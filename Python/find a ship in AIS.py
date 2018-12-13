import pandas as pd

def main() :
    df = pd.read_pickle('AIS juli 2018.pkl') 

    print(df.head())


if __name__ == '__main__':
    main()