"Simpel indlæsning af AIS Messages"
import locale
import os
from timeit import default_timer as timer
import pandas as pd
import psutil
import cx_Oracle
locale.setlocale(locale.LC_ALL, 'Danish_Denmark.1252')
process = psutil.Process(os.getpid())
conn = cx_Oracle.connect('/@STATPROD')
sql = """
select p.tid,
       p.aisnum,
       p.repeat,
       p.userid,
       p.status,
       p.rot,
       p.sog,
       p.posacc,
       p.cog,
       p.thead,
       p.manind,
       p.lon,
       p.lat
  from u900001.aispos p
 where p.tid between timestamp '2018-09-10 00:00:00'
                 and timestamp '2018-09-10 23:59:59'
"""
start = timer()
df = pd.read_sql(sql, con=conn)
end = timer()
print(f"Rækker for dagen: {df.shape[0]:<n}")
print(f"Sekunder for indlæsning: {(end - start):<.1f}")
print(f"Memory forbrug: {round(process.memory_info().rss / 1024 / 1024):<n} Mbytes")
conn.close()

df.head()