import csv

areas = dict()

with open('AreaNameEnum.csv') as f:
    dets = csv.reader(f,delimiter = ',')
    line_count = 0
    for row in dets:
        if(line_count == 0):
            line_count += 1
        else:
            areas[int(row[0])] = row[1]