import pandas as pd, geopandas as gpd
from shapely.geometry import Point



def main() :
    df = pd.read_pickle('AIS september 2018.pkl')
    print(df.shape)

    havne = pd.read_pickle('havnegrænse.pkl')

    print(havne.shape, '\n', type(havne), '\n', havne.head())



if __name__ == '__main__':
    main()
