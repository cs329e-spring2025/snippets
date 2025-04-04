import json
import numpy
import vertexai
from vertexai.generative_models import GenerativeModel
from pyspark.sql.types import StructField, StructType, StringType

region = "us-central1"
model_name = "gemini-2.0-flash-001"

prompt = """For each aircraft, provide the icao and iata codes that best fit its description.
For example, if I give you the aircraft 'Boeing 737', return the icao code 'B737' and the iata code '73G'.
If you can't find the icao or iata code, return null.
Do not provide an explanation with your answer. Do not include the index of the aircraft in your answer. 
Format your answer as a list of dictionaries, with the schema: {name<string>, icao<string>, iata<string>}.
For example, {"name": "Boeing 737", "icao": "B737", "iata": "73G"}
"""

def do_inference(aircrafts):
    
    print("enter do_inference()")
    
    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([aircrafts, prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("resp_text:", resp_text)
    
    try:
        json_objs = json.loads(resp_text)
    except Exception as e:
        print("Error while parsing json:", e, ". The error was caused by:", resp_text)
        return {}
        
    return json_objs


def remove_index(curr_str):
    
    while True:
        if curr_str[0].isdigit():
            curr_str = curr_str[1:]
        else:
            break
    
    return curr_str.strip()


def model(dbt, session):
    
    input_df = dbt.ref("aircrafts")
    
    num_aircrafts = input_df.count()
    print("num_aircrafts:", num_aircrafts)
    
    batch_size = 2
    num_batches = int(num_aircrafts / batch_size)
    combined_results = []
    
    pandas_df = input_df.select("name").filter("icao is null or iata is null").distinct().toPandas()
    batches = numpy.array_split(pandas_df, num_batches)
    
    for i in range(num_batches):
        subset_aircrafts = batches[i].to_string(header=False)
        print("subset_aircrafts:", subset_aircrafts)
        
        if "Empty DataFrame" in subset_aircrafts:
            break
        
        subset_aircrafts_clean = remove_index(subset_aircrafts)
        print("subset_aircrafts_clean:", subset_aircrafts_clean)
        
        results = do_inference(subset_aircrafts_clean)
        combined_results.extend(results)

    schema = StructType([
        StructField("name", StringType(), True),
        StructField("icao", StringType(), True),
        StructField("iata", StringType(), True)
    ])

    output_df = session.createDataFrame(combined_results, schema)
     
    return output_df