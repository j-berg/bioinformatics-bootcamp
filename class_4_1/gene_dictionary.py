import sys
import pandas as pd

# Set global variables
type_col = 2
metadata_col = 8

# Parse user arguments
def parse_args():
    if len(sys.argv) != 3:
        raise Exception("Too few or too many arguments provided.")

    print("Running script:", sys.argv[0])
    print("With options:")
    print("GTF file:", sys.argv[1])
    print("Datatable file:", sys.argv[2])
    gtf_url = sys.argv[1]
    df_url = sys.argv[2]

    return gtf_url, df_url

# Use an organism’s GTF file as input
def read_gtf(gtf_url):
    gtf = pd.read_csv(
        str(gtf_url),
        sep = '\t',
        header = None,
        comment = '#',
        low_memory = False
    )
    return gtf

# Import user datatable
def read_df(df_url):
    data = pd.read_csv(
        str(df_url),
        sep = '\t',
        index_col = 0,
        low_memory = False
    )
    return data

# Parse out matching gene IDs and names
def make_dictionary(gtf, type_id="gene"):

    gtf_c = gtf.copy()
    gtf_c = gtf_c.loc[gtf_c[type_col] == type_id]

    gtf_c['intermediate_id'] = gtf_c[8].str.split('gene_id \"').str[1]
    gtf_c['id'] = gtf_c['intermediate_id'].str.split('\"; ').str[0]

    gtf_c['intermediate_name'] = gtf_c[8].str.split('gene_name \"').str[1]
    gtf_c['name'] = gtf_c['intermediate_name'].str.split('\"; ').str[0]

    gene_dict = pd.Series(gtf_c['name'].values,index=gtf_c['id']).to_dict()

    return gene_dict

# Map gene dictionary to row names
def map_index(data, gene_dict):

    data_c = data.copy()
    data_c['new_name'] = data_c.index.to_series().map(gene_dict)
    data_c['new_name'] = data_c['new_name'].fillna(data_c.index.to_series())
    data_c = data_c.set_index('new_name')
    data_c.index.name = None

    return data_c

# Output modified table
def output_modified(data, data_url):

    output_name = data_url.split('.')[0]
    suffix = data_url.split('.')[1]
    save_name = str(output_name) + '_renamed.' + str(suffix)
    data.to_csv(
        str(save_name),
        sep='\t'
    )

# Main
#
gtf_url, df_url = parse_args()
gtf = read_gtf(gtf_url)
data = read_df(df_url)
gene_dict = make_dictionary(gtf)
data_mapped = map_index(data, gene_dict)
output_modified(data_mapped, df_url)
