import json
import vertexai
from vertexai.generative_models import GenerativeModel
from google.cloud import bigquery

region = "us-central1"
model_name = "gemini-2.0-flash-001"
prompt = """Here is a list of names.
I want you to check if the name corresponds to a real airport. If it does, return the original name and country, along with the icao code, iata code, city, state or province, and country.
Return the results as a properly formatted json object with only one json object per line.
Return only one answer per airport.
Don't return the records which are not airports.
Don't return any empty json objects.
Don't return an explanation for your answer.
Here are some sample runs:

I pass you:
"Los Angeles International Airport, United States"
"Adak Airport, United States"
"TX Airport, United States"

You return:
{"name": "Los Angeles International Airport", "icao": "KLAX", "iata": "LAX", "city": "Los Angelos", "state": "CA", "country": "United States"}
{"name": "Adak Airport", "icao": "PADK", "iata": "ADK", "city": "Adak Island", "state": "AK", "country": "United States"}
"""
sql = """select distinct name, country from dbt_air_travel_int.tmp_airports
where icao is null and name is not null and country is not null
"""

def do_inference(airports):
    
    print("enter do_inference()")
    
    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([airports, prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("resp_text:", resp_text)
    
    try:
        json_objs = json.loads(resp_text)
    except Exception as e:
        print("Error while parsing json:", e, ". The error was caused by:", resp_text)
        return {}
        
    return json_objs

def model(dbt, session):
    
    input_df = dbt.ref("tmp_airports")
    
    num_airports = input_df.count()
    batch_size = 10
    num_batches = int(num_airports / batch_size)
    combined_results = []
    
    pandas_df = input_df.select("name").sort("name").distinct().toPandas()
    batches = numpy.array_split(pandas_df, num_batches)
    
    for i in range(num_batches):
        subset_airports = batches[i].to_string(header=False)
        print("subset_airports:", subset_airports)
        results = do_inference(subset_airports)
        combined_results.extend(results)

    print("combined_results:", combined_results)
    output_df = session.createDataFrame(combined_results)
     
    return output_df