---
layout: post
title: "Arrays without loops"
author: Brendan O'Dowd
---

This post highlights some handy functions which can be applied to arrays without using loops. These are much neater than trying to produce the same outputs using loops. 

Let's imagine we're dealing with the same EARNINGS dataset as the previous post:

| Name | Year_1 | Year_2 | Year_3 |Year_4|
|--- | --- | --- | --- | ---|
|Tom|25|28|30|32|
|Mary|45|45|45|45|
|Joe| | |27|30|
|Kate|31|33| |35|
|Ben|60|55|65|70|

We'll start with some simple functions like `sum()` and `mean()`. There is also `min()`, `max()`, `median()` and several others which work in the same way. Note the structure which includes `of` and `[*]` to indicate the whole array. The last function `coalesce()` is not so obvious; it returns the first non-missing entry in the array, which is the first column for everyone and 27 for Joe. It can be applied to array of numerical variables, there is a function called `coalescec()` for character arrays. 

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array income_array year1-year4;
  total_income = sum(of income_array[*]);
  mean_income = mean(of income_array[*]);
  first_income = coalesce(of income_array[*]);
run;
{% endhighlight %}

Arrays can be handy for proofing data. Let's use another dataset, called AGES, which contains the ages of people according to several different data sources. We would like to check for inconsistencies across the array. Bob is the only one with an inconsistency, while Joe does not have data from source_2.

{% highlight sas %}
data AGES;
  input name $ age_source_1 age_source_2 age_source_3;
  datalines;
tom 21 21 21
may 31 31 31
bob 24 33 24
amy 30 30 30 
joe 25 . 25
;
run;
{% endhighlight %}

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

Now let's look at some arrays of character variables, and we'll deal with addresses. Very often addresses come in in a series of columns, and there is often no guarantee that equivalent address levels (e.g. county) will appear in the same column for different records. 

{% highlight sas %}
data ADDRESSES;
  length address_1 address_2 address_3 $ 30;
  infile datalines dsd;
  input address_1 address_2 address_3 $;
  datalines;
The White House , Mayo, ,
15 Oak Road , Killarney , Kerry
Church St 105, Swords , Dublin
;
run;
{% endhighlight %}

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
