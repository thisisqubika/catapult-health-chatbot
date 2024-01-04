from src.llm.input_evaluator import InputEvaluatorLLM
from src.llm.query_generator import QueryGeneratorLLM
from src.llm.simple_generator import SimpleGeneratorLLM
from src.llm.error_feedback import ErrorFeedbackLLM
from src.llm.chart_generator_with_sql import ChartGeneratorLLMFromSQL
from src.config import create_session
from snowflake.connector import ProgrammingError
from snowflake.snowpark.exceptions import SnowparkSQLException
import re
import base64
from io import BytesIO
import pandas as pd



class AppLogic:
    def __init__(self):
        # Create Snowflake session
        self.snowflake_session = create_session()
        self.session_created = self.snowflake_session

        # Initialize the generators
        self.input_evaluator = InputEvaluatorLLM()
        # self.system_generator = SystemGeneratorLLM(_snowflake_session=self.snowflake_session)
    
    def handle_input(self, prompt):
        user_input = prompt
        response_data = []  # List to store results from each query

        if user_input:
            # Evaluate the user input
            evaluation = self.input_evaluator.evaluate(user_input)
            if evaluation.is_a_query:
                attempts = 0
                max_retries = 3
                error_feedback = None

                while attempts < max_retries:
                    try:
                        # Generate the SQL query
                        if error_feedback:
                            query_generator = ErrorFeedbackLLM(self.snowflake_session)
                            query_to_snowflake = query_generator.generate_response(user_input, error_feedback)
                        else:
                            query_generator = QueryGeneratorLLM(self.snowflake_session)
                            query_to_snowflake = query_generator.generate_response(user_input)

                        # Extract SQL queries from the response
                        sql_queries = re.findall(r"```sql\n(.*?)\n```", query_to_snowflake, re.DOTALL)
                        if sql_queries:
                            for query in sql_queries:
                                result = self.session_created.sql(query).collect()
                                result_dicts = [{col: row[col] for col in row._fields} for row in result]
                                result_df = pd.DataFrame(result_dicts)

                                result_json = result_df.to_json(orient='records')

                                # Append the result to the response data
                                response_data.append({
                                    "query": query,
                                    "result": result_json
                                })
                            break 

                    except (ProgrammingError, SnowparkSQLException) as e:
                        # Capture the error feedback and show it in the placeholder
                        error_feedback = str(e)
                        attempts += 1
                        if attempts >= max_retries:
                            print("All attempts failed.")
                            break
    
                        
                if evaluation.include_chart:
                    chart_generator = ChartGeneratorLLMFromSQL(_snowflake_session=self.session_created)
                    chart = chart_generator.generate_chart(user_input, message['results'])

                    # Create a dictionary to hold the local variables after exec() is called
                    local_vars = {}

                    try:
                        # Remove the markdown code block formatting and fig.show()
                        code_to_exec = chart.replace("```python\n", "").replace("```", "").replace("fig.show()", "").strip()
                        print("Executing code:", code_to_exec)  # Printing the corrected code for verification
                        exec(code_to_exec, {}, local_vars)

                        if 'fig' in local_vars:
                            fig = local_vars['fig']
                            # Convert Plotly figure to an image (PNG)
                            image_buffer = BytesIO()
                            fig.write_image(image_buffer, format='png')
                            image_buffer.seek(0)

                            # Encode the image in base64
                            base64_image = base64.b64encode(image_buffer.read()).decode('utf-8')

                            # You can now send this base64 encoded string in your HTTP response
                            encoded_image_data = f"data:image/png;base64,{base64_image}"
                            
                            # Append the encoded image data to your response
                            response_data.append({
                                "chart": encoded_image_data
                            })
                        else:
                            print("Plot object 'fig' not found in the executed code.")

                    except Exception as e:
                       print(f"An error occurred while executing the code: {e}")

                # if attempts == max_retries:
                #     st.error("Failed to execute query after several attempts.")
                        

                else:
                    return response_data
                
                    
            else:
                # Handle non-query input (e.g., greetings, thanks)
                simple_generator = SimpleGeneratorLLM(_snowflake_session=self.snowflake_session)
                response = simple_generator.generate_response(user_input)
                message = {"role": "assistant", "content": response}
                return 
        
        else:
            return


