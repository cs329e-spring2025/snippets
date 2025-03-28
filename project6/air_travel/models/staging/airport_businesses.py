import json
import vertexai
from vertexai.generative_models import GenerativeModel
from google.cloud import bigquery

region = "us-central1"
model_name = "gemini-2.0-flash-001"
prompt = """Go through this list of business names and standardize them to remove the variations in spelling.
For example, 'Sweet Jill Bakery' and 'Sweet Jill's Bakery' both refer to the same business, so standardize on one or the other.
Another example is, 'Alaska Airline' and 'Alaska Airlines'. Since they both refer to the same business, standardize on 'Alaska Airlines'.
Suggest a standard name, mapping the current one to the new one.
Return the list of original business names along with their updated names.
Format the results as a json object with the schema: current_name:string, new_new:string.
Do not include any unchanged business names with your answer.
Do not include an explanation with your answer.
"""

def do_inference(input_str):

    vertexai.init(location=region)
    model = GenerativeModel(model_name)
    resp = model.generate_content([input_str, prompt])
    resp_text = resp.text.replace("```json", "").replace("```", "").replace("\n", "")
    print("resp_text:", resp_text)

    names = json.loads(resp_text)
    
    replacements = {}

    # names can be either a dictionary or list type (depending on what the LLM decides to do!)
    if type(names) == dict:
        for old, new in names.items():
            if old == new:
                continue
            else:
                replacements[old] = new

    if type(names) == list:
        for name_entry in names:
            if name_entry['current_name'] == name_entry['new_name']:
                continue
            else:
                replacements[name_entry['current_name']] = name_entry['new_name']

    return replacements


def model(dbt, session):
   
    # dbt.config(post_hook = "drop table dbt_air_travel_stg.tmp_business_categories")
    
    business_names_sql = "select distinct business from dbt_air_travel_stg.tmp_business_categories order by business"
    bq_client = bigquery.Client()
    rows = bq_client.query_and_wait(business_names_sql)

    batch_size = 500
    business_names = []
    combined_replacements = {}

    for i, row in enumerate(rows):

        business_names.append(row["business"])

        if i > 0 and i % batch_size == 0:
            # process batch
            print("processing batch")
            business_names_str = '\n'.join(business_names)
            replacements = do_inference(business_names_str)
            combined_replacements.update(replacements)

            # reset business_names to process next batch
            business_names = []

    if len(business_names) > 0:
        print("processing last batch")
        business_names_str = '\n'.join(business_names)
        replacements = do_inference(business_names_str)
        combined_replacements.update(replacements)

    print("combined_replacements:", combined_replacements)

    # read the source table (i.e. the tmp table which was produced by the previous python model)
    businesses_df = dbt.ref("tmp_business_categories") 
    
    # merge the new business names using pyspark's replace()
    # https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.DataFrame.replace.html
    output_df = businesses_df.na.replace(combined_replacements, "business")
    
    return output_df