from llm.input_evaluator import InputEvaluatorLLM
from llm.query_generator import QueryGeneratorLLM
from llm.system_generator import SystemGeneratorLLM
from llm.simple_generator import SimpleGeneratorLLM
# from llm.chart_generator import ChartGeneratorLLM
from llm.chart_generator_with_sql import ChartGeneratorLLMFromSQL
from config import create_session
from snowflake.connector import ProgrammingError
from snowflake.snowpark.exceptions import SnowparkSQLException
import re
import streamlit as st
import pandas as pd

class AppLogic:
    def __init__(self):
        # Create Snowflake session
        self.snowflake_session = create_session()
        self.session_created = self.snowflake_session

        # Initialize the generators
        self.input_evaluator = InputEvaluatorLLM()
        self.system_generator = SystemGeneratorLLM(_snowflake_session=self.snowflake_session)
    
    def handle_input(self, prompt, session_state):
        user_input = prompt
        if user_input:

            # Evaluate the user input
            evaluation = self.input_evaluator.evaluate(user_input)
            
            if evaluation.is_a_query:
                # Generate the SQL query
                query_generator = QueryGeneratorLLM(_snowflake_session=self.session_created)

                attempts = 0
                max_retries = 3

                while attempts < max_retries:
                    query_to_snowflake = query_generator.generate_sql_query(user_input)
                    resp_container = st.empty()
                    
                    response = resp_container.markdown(query_to_snowflake)
                    message = {"role": "assistant", "content": response}

                    sql_queries = re.findall(r"```sql\n(.*?)\n```", query_to_snowflake, re.DOTALL)
                    if sql_queries:
                        query = sql_queries[-1]
                        try:
                            message['results'] = self.session_created.sql(query).collect()
                            st.dataframe(message["results"])
                            # Append results to the chat history
                            session_state.messages.append(message)
                            break

                        except (ProgrammingError, SnowparkSQLException) as e:
                            st.warning(f"Attempt {attempts + 1} failed: {e}")
                            # new_loader.empty()
                            attempts += 1
                            # return session_state
                        
                if evaluation.include_chart:
                    new_loader = st.empty()
                    new_loader.text("Loading... please wait. ")
                    chart_generator = ChartGeneratorLLMFromSQL(_snowflake_session=self.session_created)
                    chart = chart_generator.generate_chart(user_input, message['results'])

                    # Create a dictionary to hold the local variables after exec() is called
                    local_vars = {}

                    try:
                        # Remove the markdown code block formatting and fig.show()
                        code_to_exec = chart.replace("```python\n", "").replace("```", "").replace("fig.show()", "").strip()
                        new_loader.empty()
                        print("Executing code:", code_to_exec)  # Printing the corrected code for verification
                        exec(code_to_exec, {}, local_vars)

                        if 'fig' in local_vars:
                            fig = local_vars['fig']
                            st.plotly_chart(fig)
                            # Append message to the chat history
                            message = {"role": "assistant", "content": fig}
                            session_state.messages.append(message)
                        else:
                            st.error("Plot object 'fig' not found in the executed code.")
                    except Exception as e:
                        st.error(f"An error occurred while executing the code: {e}")

                # if attempts == max_retries:
                #     st.error("Failed to execute query after several attempts.")
                        
                #CHECK IF WE ALSO NEED A GRAPH:

                else:
                    return session_state
                
                    
            else:
                # Handle non-query input (e.g., greetings, thanks)
                simple_generator = SimpleGeneratorLLM(_snowflake_session=self.snowflake_session)
                response = simple_generator.generate_response()
                message = {"role": "assistant", "content": response}
                session_state.messages.append(message)
                return session_state
        
        else:
            return  session_state


