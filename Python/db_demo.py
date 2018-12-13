import cx_Oracle
print(cx_Oracle.clientversion)
print(cx_Oracle.version)
print(cx_Oracle.buildtime)


def print_row(row):
    print('{0} {1} {2} {3}'.format(row[0], row[1], row[2], row[3]))
    if row[2] == None:
        return 0
    else:
        return row[2]


conn = cx_Oracle.connect('/@STATPROD')
# Start transaktion, unødvendig her, relevant hvis man vil gruppere operationer i transaktioner.
conn.begin()
cur = conn.cursor()
cur.arraysize = 1000
cur.execute('select d.owner, d.table_name, d.num_rows, d.rn from (select dt.owner, dt.table_name, dt.num_rows, row_number () over (order by dt.num_rows desc nulls last) rn from dba_tables dt) d where rn < 12345678')
tot = 0
while True:
    rows = cur.fetchmany()
    for i in rows:
        tot += print_row(i)
    if len(rows) < cur.arraysize:
        break
print(tot)

conn.commit()  # Afslut transaktion med commit eller conn.rollback()
cur.close()
conn.close()
