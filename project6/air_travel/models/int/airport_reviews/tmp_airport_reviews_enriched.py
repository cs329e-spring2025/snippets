
import json
import pandas
import numpy
from pyspark.sql import Row
import vertexai
from vertexai.generative_models import GenerativeModel, HarmCategory, HarmBlockThreshold, SafetySetting

region = "us-central1"
model_name = "gemini-2.0-flash-001"
prompt = """Go through the list of reviews that I pass you and apply the following logic:
    If a review refers to an airport, return relevant = True, otherwise return relevant = False.
    If a review's sentiment is positive, return 'positive'; if it's negative, return 'negative'; if it's mixed, return 'mixed'. If it's neutral, return 'neutral'. If it's none of these, return 'other'.  
Return the review's id, relevance, and sentiment.
Format the results as a list of json objects with the schema: [{"id" : integer, "relevant" : boolean, "sentiment" : string}]
Do not include an explanation with your answer.

Here's what the output should look like:
[{"id" : 123, "relevant" : true, "sentiment" : 'positive'},
{"id" : 456, "relevant" : true, "sentiment" : 'mixed'},
{"id" : 789, "relevant" : true, "sentiment" : 'other'}]
"""

safety_config = [
    SafetySetting(
        category=HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold=HarmBlockThreshold.BLOCK_ONLY_HIGH,
    ),
]

def do_inference(input_str):

    results = [] # to contain list of analyzed reviews
    
    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([input_str, prompt], safety_settings=safety_config)
    
    prompt_token_count = resp.usage_metadata.prompt_token_count
    candidate_token_count = resp.usage_metadata.candidates_token_count
  
    if candidate_token_count == 0 or candidate_token_count == 8192: 
        # something likely went wrong, fail fast
        return results
    
    print("resp:", resp)
    
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("resp_text:", resp_text)

    try:
        results = json.loads(resp_text)
    except Exception as e:
        print("Error while parsing json:", e, ". The error was caused by:", resp_text)
        return []

    return results


def model(dbt, session):
    
    input_df = dbt.ref("tmp_airport_reviews")
    num_reviews = input_df.count()
    print("num_reviews:", num_reviews)

    batch_size = 10
    num_batches = int(num_reviews / batch_size)
    combined_results = []
    
    pandas_df = input_df.select("id", "subject", "body").filter("id is not null and subject is not null and body is not null").toPandas()
    batches = numpy.array_split(pandas_df, num_batches)
    
    for i in range(num_batches):
        subset_reviews = batches[i].to_string(header=False)
        print("subset_reviews:", subset_reviews)
    
        results = do_inference(subset_reviews)
        combined_results.extend(results)

    print("combined_results:", combined_results)
    output_df = session.createDataFrame(Row(**x) for x in combined_results)
    output_df.show(truncate=False)
    
    return output_df
