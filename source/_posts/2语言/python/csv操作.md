---
title: python 操作 csv
date: 2016-08-05 03:30:09
tags: 
  - python
categories: [语言,python]
---

# csv 操作

[TOC]

## 读取 csv文件

```python
import pandas as pd
data = pd.read_csv('预测数据.csv')
```

## 查看前几行

```
headdata = data.head(5)
print(headdata)
```

## 获取行

### 某行

```
# 第一行
print(data.ix[0,:]) 
```

```
apply_cnt                 1.000000e+00
bbr_addressno             1.000000e+00
...
tbr_appntsex              1.000000e+00
tbr_lccont_cnt            1.000000e+00
tbr_marriage              7.000000e+00
tbr_year_prem             3.251000e+03
predictScoreColumnName    4.527450e-01
Name: 0, dtype: float64
```

### 某几行

```
#获取第2/4/6行的数据
print(data.ix[[1,3,5],:])
```

```
   apply_cnt  bbr_addressno  bbr_age  bbr_is_has_medica  bbr_marriage  \
1        1.0           15.0     39.0                0.0           7.0   
3        1.0            0.0      2.0                0.0           8.0   
5        1.0            2.0     54.0                0.0           1.0   

   bbr_sex  bd_amnt_sum  bd_lccont_year  dir_work_time  dlr_bd_chuxian  \
1      1.0    3131300.0           258.0         3031.0             1.0   
3      0.0     180000.0           419.0          881.0             1.0   
5      1.0     220000.0           181.0          227.0             1.0   

            ...            prt_accidentdate_del  self_pol  tabfeemoney  \
1           ...                            32.0       1.0      4602.10   
3           ...                             3.0       0.0     15090.84   
5           ...                            -1.0       0.0     54939.69   

   tbr_accilccont_cnt  tbr_age  tbr_appntsex  tbr_lccont_cnt  tbr_marriage  \
1                 0.0     39.0           1.0             8.0           7.0   
3                 0.0     32.0           0.0             2.0           7.0   
5                 0.0     23.0           0.0             2.0           1.0   

   tbr_year_prem  predictScoreColumnName  
1        31436.0                0.448217  
3         9300.0                0.693983  
5         7048.0                0.332433  

[3 rows x 30 columns]
```

### 所有行

```
print(data.ix[:, :])
```



## 获取列

### 某列

```
print(data['label'])
```

 ```
print(data.ix[:, 'label'])
 ```

```
0        0.0
1        0.0
2        0.0
3        0.0
4        1.0
        ... 
18489    0.0
18490    0.0
18491    0.0
18492    0.0
Name: label, Length: 18493, dtype: float64
```

### 某几列

```
print(data.ix[:, ['label','predictScoreColumnName','comment']])
```

```
       label  predictScoreColumnName  comment
0        0.0                0.452745      NaN
1        0.0                0.448217      NaN
...      ...                     ...      ...
18491    0.0                0.359486      NaN
18492    0.0                0.317408      NaN

[18493 rows x 3 columns]
```

## 数据统计

describe统计下数据量、标准值、平均值、最大值等

```
print(data.describe())
```

运行效果

```
          apply_cnt  bbr_addressno      bbr_age  bbr_is_has_medica  
count  18493.000000   18493.000000  18493.00000       18493.000000   
mean       1.300384       2.078246     36.21473           0.184502   
std        0.909737       3.669211     14.59485           0.387904   
min        1.000000      -1.000000      0.00000           0.000000   
25%        1.000000       0.000000     31.00000           0.000000   
50%        1.000000       1.000000     40.00000           0.000000   
75%        1.000000       3.000000     46.00000           0.000000   
max       30.000000     148.000000     71.00000           1.000000 
```