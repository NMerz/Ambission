from firebase_functions import https_fn
from firebase_admin import initialize_app

from openai import OpenAI
from dotenv import load_dotenv

import stable_whisper

import requests

from typing import Any
import uuid
import datetime
from google.cloud import storage
import google.auth as auth
import firebase_functions.options as options
import google.auth.transport.requests as auth_requests
import google.oauth2.id_token

load_dotenv()

client = OpenAI()

model = stable_whisper.load_model("base")


initialize_app()


@https_fn.on_call(memory=options.MemoryOption.GB_2)
def makeCaptions(req: https_fn.CallableRequest) -> Any:
    storage_client = storage.Client()
    print(req)
    bucket = storage_client.bucket("video-resume-4fcd0.appspot.com")
    blob = bucket.blob(req.data["blob"])
    input_file = str(uuid.uuid1())
    blob.download_to_filename(input_file)
    new_result = model.align(input_file, req.data["text"], language="en")
    print(new_result)
    output_file = str(uuid.uuid1()) + ".vtt"
    new_result.to_srt_vtt(output_file, word_level=False)
    out_blob = bucket.blob(output_file)
    generation_match_precondition = 0
    out_blob.upload_from_filename(
        output_file, if_generation_match=generation_match_precondition
    )
    credentials, project_id = auth.default()
    if credentials.token is None:
        # Perform a refresh request to populate the access token of the
        # current credentials.
        credentials.refresh(auth_requests.Request())
    url = out_blob.generate_signed_url(
        version="v4",
        service_account_email=credentials.service_account_email,
        access_token=credentials.token,
        expiration=datetime.timedelta(minutes=15),
        method="GET",
    )
    return url


def getToneContext(tone: str) -> str:
    if tone == "technical":
        gpt_context = "You are conscientious and detail-oriented. Always include specific technologies. Use surprising words. You are the speaker."
    elif tone == "fun":
        gpt_context = (
            "You are a zany generalist. Always include specifics. Use surprising words."
        )
    elif tone == "professional":
        gpt_context = "You are a down-to-earth generalist. Always include specifics. Use surprising words."
    else:
        return ""
    return gpt_context


@https_fn.on_call(memory=options.MemoryOption.GB_2)
def makeScript(req: https_fn.CallableRequest) -> Any:
    print(req)
    tone = req.data["tone"]
    gpt_context = getToneContext(tone)
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
    return refineRaw(completion.choices[0].message.content, tone != "fun")


@https_fn.on_call(memory=options.MemoryOption.GB_2)
def extractJobDescription(req: https_fn.CallableRequest) -> Any:
    print(req)
    if req.data["uselessAuth"] != "FDKNE@!IORjr3kl23i23":
        return None

    print(req.data["jobUrl"])
    auth_req = auth_requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(
        auth_req, "https://chrome-it-ocw5hqhnra-uc.a.run.app"
    )
    response = requests.post(
        url="https://chrome-it-ocw5hqhnra-uc.a.run.app",
        json={"url_to_chrome": req.data["jobUrl"]},
        headers={"Authorization": f"Bearer {id_token}"},
    )
    print(response.status_code)
    jobHtml = response.content.decode()
    print(jobHtml)
    if response.status_code != 200:
        return None

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "user",
                "content": """Extract the job description from the html and return it as text:
    """
                + jobHtml,
            },
        ],
    )
    print(completion.choices[0].message.content)
    return completion.choices[0].message.content


@https_fn.on_call(memory=options.MemoryOption.GB_2)
def makeRecruiterScript(req: https_fn.CallableRequest) -> Any:
    print(req)
    tone = req.data["tone"]
    gpt_context = getToneContext(tone)
    completion = client.chat.completions.create(
        model="gpt-4-turbo",
        messages=[
            {
                "role": "system",
                "content": gpt_context
                + """Your resume is:
    """
                + req.data["resume"],
            },
            {
                "role": "user",
                "content": """Address the listener. Not a letter. Be concise. Use <900 characters. Lead with technologies. Where does your resume overlap with this description:"
    """
                + req.data["jobDescription"],
            },
        ],
    )
    return refineRaw(
        completion.choices[0].message.content,
        False,
    )


def refineRaw(raw: str, summarize: bool) -> str:
    ongoing = raw
    if summarize:
        print(raw)
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": "You care about exact replication.",
                },
                {
                    "role": "user",
                    "content": f"Condense the following: {raw}",
                },
            ],
        )
        print(completion.choices[0].message.content)
        ongoing = completion.choices[0].message.content

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You care about exact replication.",
            },
            {
                "role": "user",
                "content": f'rewrite using "I"/"we": {ongoing}',
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
