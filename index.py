from src.app import main


def handler(event, context):
    return main(event, context)


if __name__ == "__main__":
    try:
        handler(None, None)
    except Exception as e:
        print(e)
