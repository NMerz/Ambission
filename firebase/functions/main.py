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
    if req.data["tone"] == "technical":
        gpt_context = "You are conscientious and detail-oriented. Always include specific technologies. Use surprising words. You are the speaker."
    elif req.data["tone"] == "fun":
        gpt_context = (
            "You are a zany generalist. Always include specifics. Use surprising words."
        )
    elif req.data["tone"] == "professional":
        gpt_context = "You are a down-to-earth generalist. Always include specifics. Use surprising words."
    else:
        return ""
    completion = client.chat.completions.create(
        model="gpt-4-turbo",
        messages=[
            {
                "role": "system",
                "content": gpt_context,
            },
            {
                "role": "user",
                "content": """Highlighting experience, provide a concise elevator pitch for the following resume:
    """
                + req.data["resume"],
            },
        ],
    )

    if req.data["tone"] != "fun":
        print(completion.choices[0].message.content)
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You care about exact replication.",
                },
                {
                    "role": "user",
                    "content": f"Condense the following: {completion.choices[0].message.content}",
                },
            ],
        )

    print(completion.choices[0].message.content)
    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You care about exact replication.",
            },
            {
                "role": "user",
                "content": f'rewrite using "I"/"we": {completion.choices[0].message.content}',
            },
        ],
    )

    print(completion.choices[0].message.content)
    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "user",
                "content": f"insert a new line between each sentence:\n{completion.choices[0].message.content}",
            },
        ],
    )
    print(completion.choices[0].message.content)
    return completion.choices[0].message.content
