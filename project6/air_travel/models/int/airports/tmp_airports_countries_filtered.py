import json
import vertexai
from vertexai.generative_models import GenerativeModel
from pyspark.sql.types import StructField, StructType, StringType

region = "us-central1"
model_name = "gemini-2.0-flash-001"

prompt = """Find a match for each country that I pass you based on the reference countries list below.
For example, if I pass you the country 'Syrian Arab Republic', map it to 'Syria'.
If there is no good match, default to null
Format your answer as a list of dictionaries, using the schema: {"current" : string, "new" : string}.
For example: [{"current": "Syrian Arab Republic", "new": "Syria"}, {"current": "Swaziland", "new": "Eswatini"}, {"current": "ACTIVE AERO", "new": null}]. 
Here is the list of reference countries: \n
"""

def model(dbt, session):
    
    country_df = dbt.ref("Country")
    country_orphans_df = dbt.ref("tmp_airports_countries_orphan") # countries in the airports table which don't exist in the Country table

    num_country = country_df.count()
    print("num_country:", num_country)

    num_country_orphans = country_orphans_df.count()
    print("num_country_orphans:", num_country_orphans)

    country_str = country_df.select("name").toPandas().to_string(header=False)
    country_orphans_str = country_orphans_df.select("country").toPandas().to_string(header=False)

    complete_prompt = prompt + country_str
    print("complete_prompt:", complete_prompt)

    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([country_orphans_str, complete_prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("results_text:", resp_text)
    
    try:
        replacements = json.loads(resp_text)
        print("replacements:", replacements)
    except Exception as e:
        print("Error while parsing json:", e, ". The error was caused by:", resp_text)
        return {}

    schema = StructType([
        StructField("current", StringType(), True),
        StructField("new", StringType(), True),
    ])

    output_df = session.createDataFrame(replacements, schema)

    return output_df