import json, numpy
import vertexai
from vertexai.generative_models import GenerativeModel

region = "us-central1"
model_name = "gemini-2.0-flash-001" 
prompt = """Please check if each name that I pass you is an actual airport. If it is, return the airport name along with the airport's icao code, iata code, city, state or province, and country 
conforming to the schema: {"name": string, "icao": string, "iata": string, "city": string, "state": string, "country": string}.
Return your answer as a list of json objects.
Return only one answer per airport.
If a name is not a real airport, don't include it in your answer. 
Don't return any empty json objects.
Don't return an explanation with your answer.
Here are is an example run:

If I pass you:
"Los Angeles International Airport United States"
"Adak Airport United States"
"TX Airport United States"

You would return:
[{"name": "Los Angeles International Airport", "icao": "KLAX", "iata": "LAX", "city": "Los Angelos", "state": "CA", "country": "United States"},
{"name": "Adak Airport", "icao": "PADK", "iata": "ADK", "city": "Adak Island", "state": "AK", "country": "United States"}]
"""

def do_inference(input_airports):
    
    print("enter do_inference()")
    
    vertexai.init(location=region)
    model = GenerativeModel(model_name=model_name)
    resp = model.generate_content([input_airports, prompt])
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
    print("num_batches:", num_batches)
    combined_results = []
    
    # process only the airports with missing icao
    pandas_df = input_df.where("icao is NULL and name is not NULL and country is not NULL").select("name", "country").sort("name").distinct().toPandas()
    batches = numpy.array_split(pandas_df, num_batches) 
    
    for i in range(num_batches):
        input_airports = batches[i].to_string(header=False)
        print("input_airports:", input_airports)
        results = do_inference(input_airports)
        print("results:", results)
        combined_results.extend(results)

    print("converting to PySpark dataframe")
    print("combined_results:", combined_results)
    output_df = session.createDataFrame(combined_results, "name: string, icao: string, iata: string, city: string, state: string, country: string")
     
    return output_df