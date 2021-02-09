---
layout: post
title: "Arrays without loops"
author: Brendan O'Dowd
---

This post highlights some handy functions which can be applied to arrays without using loops. These are much neater than trying to produce the same outputs using loops. 

## Simple functions: `sum()`, `mean()` and `coalesce()`

Let's imagine we're dealing with the same EARNINGS dataset as the previous post:

<details>
  <summary>Click for datalines on table</summary>
  
{% highlight sas %}
data EARNINGS;
  input name $ Year_1 Year_2 Year_3 Year_4;
  datalines;
Tom 25 28 30 32
May 45 45 45 45
Bob . . 27 30
Amy 31 33 . 35
Joe 60 55 65 70
;
run;
{% endhighlight %}
</details>


| Name | Year_1 | Year_2 | Year_3 |Year_4|
|--- | --: | --:| --:| --:|
|Tom|25|28|30|32|
|May|45|45|45|45|
|Bob| .| .|27|30|
|Amy|31|33| .|35|
|Joe|60|55|65|70|

We'll start with some simple functions like `sum()` and `mean()`. There is also `min()`, `max()`, `median()` and several others which work in the same way. Note the structure which includes `of` and `[*]` to indicate the whole array. The last function `coalesce()` is not so obvious; it returns the first non-missing entry in the array, which is the first column for everyone and 27 for Bob. It can be applied to array of numerical variables, there is a function called `coalescec()` for character arrays. 

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array income_array year1-year4;
  total_income = sum(of income_array[*]);
  mean_income = mean(of income_array[*]);
  first_income = coalesce(of income_array[*]);
run;
{% endhighlight %}

<details>
  <summary>View output</summary>

<table>
<thead>
<tr>stuff</tr>
</thead>
<tbody>
<tr>more stuff</tr>
</tbody>
</table>

| Name | Year_1 | Year_2 | Year_3 |Year_4|total_income|mean_income|first_income|
|--- | --: | --:| --:| --:|--:| --:| --:|
|Tom|25|28|30|32|115|28.75|25|
|May|45|45|45|45|180|45|45|
|Bob| .| .|27|30|57|28.5|27|
|Amy|31|33| .|35|99|33|31|
|Joe|60|55|65|70|250|62.5|60|

</details>

## Using `range()`, `min()`/`max()` and `nmiss()` for proofing

Arrays can be handy for proofing data. Let's use another dataset, called AGES, which contains the ages of people according to several different data sources. We would like to check for inconsistencies across the array. Bob is the only one with an inconsistency, while Joe does not have data from source_2.


<details>
  <summary>Click for datalines on table</summary>
  
{% highlight sas %}
data AGES;
  input name $ age_source_1 age_source_2 age_source_3;
  datalines;
Tom 21 21 21
May 31 31 31
Bob 24 33 24
Amy 30 30 30 
Joe 25 . 25
;
run;
{% endhighlight %}
</details>

| Name | age_source_1 | age_source_2 | age_source_3 |
|--- | --: | --:| --:|
|Tom|21|21|21|
|May|31|31|31|
|Bob|24|33|24|
|Amy|30|30|30|
|Joe|25|.|25|


I'm going to create two flags called age_error_1 and age_error_2 which indicate if someone has more than one distinct age. The first is based on `range()`, which returns the difference between the highest and lowest entries in the array. The second provides the same output but uses the `min()` and `max()` functions. Note that missing entries are ignored in both cases. 

The last indicator here, called `missing_age`, is based on the function `nmiss()`. This function returns the number of missing entries in an array, and can be used only for arrays of numerical variables. There is an equivalent function called `cmiss()` for arrays of character variables. We'll see that in a later example.

{% highlight sas %}
data AGES;
  set AGES;
  array age_array age_source: ;
  age_error_1 = range(of age_array[*]) > 0;
  age_error_2 = min(of age_array[*]) ~= max(of age_array[*]);
  missing_age = nmiss(of age_array[*]);
run;
{% endhighlight %}

<details>
  <summary>Table</summary>

| variable | example |
|---------|----------|
| abc | 123 |

</details>


| Name | age_source_1 | age_source_2 | age_source_3 |age_error_1 |age_error_2 |missing_age|
|--- | --: | --:| --:|--: | --:| --:|
|Tom|21|21|21|0|0|0|
|May|31|31|31|0|0|0|
|Bob|24|33|24|1|1|0|
|Amy|30|30|30|0|0|0|
|Joe|25|.|25|0|0|1|

## Concatenating character arrays 

Now let's look at some arrays of character variables, and we'll deal with addresses. Very often addresses come in in a series of columns, and there is often no guarantee that equivalent address levels (e.g. county) will appear in the same column for different records. 

<details>
  <summary>Click for datalines on table</summary>
  
{% highlight sas %}
data ADDRESSES;
  length address_1 address_2 address_3 $ 30;
  infile datalines dsd;
  input address_1 address_2 address_3 $;
  datalines;
The White House , Mayo, ,
15 Oak Road , Killarney , Kerry
Church St 105, Swords , Dublin
123 Castle Hill, Swinford, Mayo 
;
run;
{% endhighlight %}
</details>

| address_1 | address_2 | address_3 | 
|--- | ---| ---|
|The White House|Mayo| |
|15 Oak Road|Killarney|Kerry|
|Church St 105|Swords|Dublin|
|123 Castle Hill|Swinford|Mayo|

We can concatenate all the variables into one new variable using `catx()`. There are [several concatenate functions](https://sasexamplecode.com/concatenate-strings-with-cat-catt-cats-catx/), but I like using `catx()` because it allows you to define the delimiter in the first argument (I'm just using a space below). 

I'm also going to make an indicator for a found string ("Mayo" in this case) which uses the `findw()` function wrapped around the same `catx()` expression. Note that in this way the concatenated expression does not have to be stored as an extra variable. 

Finally I'm using `cmiss()`, which, as explained above, returns the number of missing entries in an array of character variables. This is used to make a simple indicator called `missing_field`. 

{% highlight sas %}
data ADDRESSES;
  length full_address $ 100;
  set ADDRESSES;
  address address_array address_: ;
  full_address = catx(" " , of address_array[*]) ;
  
  if findw(catx(" " , of address_array[*])  , "Mayo" ) then mayo_ind = 1; else mayo_ind = 0;
  
  missing_field = cmiss(of address_array[*]);
run;
{% endhighlight %}

## Returning a particular index in an array

Here we look at two functions which tell you in which entry, or in which column, a particular value can be found. The first of these is `coalesec()`, which returns the first non-empty entry in an array, and has a counterpart for numberical arrays called `coalesce()`. The second is `whichc()` which returns the first match in an array to a specified search term. We'll use a small dataset called NACE which has a series of columns each indicating with a single letter the [NACE code](https://ec.europa.eu/competition/mergers/cases/index/nace_all.html) that somebody worked in within a particular month. In the dataset below Tom and May change industries once or twice, while Bob and Joe stay in the same sector and Amy joins a sector in month_3.

<details>
  <summary>Click for datalines on table</summary>
  
{% highlight sas %}
data NACE;
  length name $ 3 month_1 month_2 month_3 month_4 $ 1;
  infile datalines dsd;
  input name month_1 month_2 month_3 month_4;
  datalines;
Tom,A,B,A,A
May,R,R,Q,Q
Bob,O,O,O,O
Amy, , ,B,B
Joe,Q,Q,Q,Q
;
run;
{% endhighlight %}
</details>
| Name | month_1 | month_2 | month_3 | month_4 |
|--- | :-:| :-:|:-:|:-:|
|Tom|A|B|A|A|
|May|R|R|Q|Q|
|Bob|O|O|O|O|
|Amy| | |B|B|
|Joe|Q|Q|Q|Q|

As mentioned above, `coalescec()` which returns the first non-missing entry in a character array. We use it below to define a variable called `first_job`. 

Next I use `whichc()`, which takes a search term as its first argument and a character array as its second argument (the equivalent version for numerical arrays is called `whichn()`). This returns the index in the array corresponding to the first match of an array entry to the search term. Here my search terms is "Q", which is the NACE code for Health & Social Work. I use this to define a variable called `health_joiner`, so that I can find the month in which somebody first joined the Health & Social Work sector. Trying to do the same using loops would be much more verbose.

The fact that `whichc()` returns the index when you're already working with arrays is handy, because it makes it easy to examine neighbouring columns by adding a `+1` or `-1` to the index. Suppose, for example, we were interested in the sectors that people worked in before joining Health & Social Work. I can then use `whichc()` looking for "Q" and then stick on a `-1` to get the sector from the month before. Below I use this technique to define a variable called `before_health`.

{% highlight sas %}
data NACE;
  set NACE;
run;
{% endhighlight %}
