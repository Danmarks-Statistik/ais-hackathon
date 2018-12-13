import pandas as pd
import geopandas
from shapely.geometry import Point, box
from shapely.geometry.polygon import Polygon

def danbox(x) :
    x1, y1, x2, y2 = x.bounds
    return box(x1, y1, x2, y2)

def hent() :
    url = 'h:\python\Geodata/DK_SHAPE_UTM32-EUREF89/FOT/HYDRO/'
    havn = geopandas.read_file(url +'havn.shp').to_crs({'init': 'epsg:4326'})

    tmp = havn[havn['HAVNTYPE'] == 'Kyst']
    havn = tmp[tmp['UNDER_MIN'] == 'f']
    del(tmp)

    havn['omkreds'] = havn['geometry'].apply(danbox)
    havn.set_geometry('omkreds', inplace=True)
    havn.drop(['MOB_ID', 'FEAT_KODE', 'FEAT_TYPE', 'FEATSTATUS', 'GEOMSTATUS', 'HAVNTYPE', 'UNDER_MIN', 'geometry'], axis=1, inplace=True)
    havn.reset_index(drop=True, inplace=True)
    crs = {'init': 'epsg:4326'}
    return geopandas.GeoDataFrame(havn, crs=crs, geometry=havn.omkreds)