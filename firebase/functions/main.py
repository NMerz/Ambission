from firebase_functions import https_fn
from firebase_admin import initialize_app

from openai import OpenAI
from dotenv import load_dotenv

from typing import Any

load_dotenv()

client = OpenAI()

initialize_app()


@https_fn.on_call()
def makeScript(req: https_fn.CallableRequest) -> Any:
    completion = client.chat.completions.create(
        model="gpt-4-turbo",
        messages=[
            {
                "role": "system",
                "content": 'You are a comedian writing an elevator pitch. Always include specifics. Never reference elevators. Never say "picture this". No meastro. No wizard',
            },
            {
                "role": "user",
                "content": """Only mention 3 jobs. Reverse the order of the jobs. In first-person, provide a single-paragraph, witty, concise elevator pitch for the following resume:
    """
                + req.data["resume"],
            },
        ],
    )

    print(completion.choices[0].message.content)
    completion = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {
                "role": "user",
                "content": f"insert a newline character between each sentence:\n{completion.choices[0].message.content}",
            },
        ],
    )
    print(completion.choices[0].message.content)
    return completion.choices[0].message.content
