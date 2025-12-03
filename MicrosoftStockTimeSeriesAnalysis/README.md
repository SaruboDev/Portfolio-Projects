# Microsoft Stock 2015-2021 EDA
In this project we will do some EDA for the Microsoft 2015-2021 Stock Time Series.

## Data Description
We have a total of 6 columns:
- Date : the date time for when the features have been recorded.
- Open : signals the opening price of the stock.
- High : signals the highest value of the day.
- Low : signals the lowest value of the day.
- Close : signals the closing price.
- Volume : signals the umber of shares traded on that day.

## Data Exploration and Cleaning
### Dtypes check
First of all we might want to check the dtypes of our data, in fact, we can notice that at first, the datetime is considered an object dtype, so we will start by converting it back to a datetime format with pandas.

After that, we want to describe the data just to be able to read the statistical values from our data, which brings us to the next point, checking for duplicates and NaN values.

### Missing days check
Seeing the data, we can see that the dates seem to have been recorded once per day at 4pm. We can now print the date range from pandas to get all the ranges in a 24hour interval between each record.<br>
Checking the length, we can see that it does not match the Date count from our describe method, which means that our dataset didn't include off-days like holidays and weekends (we can see the difference in date in my print right after).

This is fine, because we don't really want to check for days when the stock market doesn't change.

### Missing values and dupe check
The first thing i did, was to check if any of the columns had duplicated values. We can see they don't, so our dataset doesn't need changes.

Now, for the NaN values, i checked _how many_ values are NaN for each date, the result is 0, which is great, but just to be sure i also checked the total percentage of NaN values across the dataset, and it confirms that we don't have any.

## First View
Given the current view of all the columns in the dataset, we can see that they all share similar shapes except for "Volume", since it's a totally different value, which indicates us how many shares got traded that day, and even then they mostly stay around the same values.

Now, just to be safe, i also wanted to check the correlation between our data, to do so, at first i did a simple heatmap without considering time, and as we can see, it didn't really give us much information other than the obvious.

Now i'll check the partial autocorrelation of the Volume, because since the others are already perfectly correlated to one another it'd be redundant to check them all to get the same shape.
With this graph we can see that the best lag for this feature is 1, meanwhile others are either in the blue area (confidence zone) or are false positive (like 9).

### Periodogram
Now, checking for any trend or stagionality inside the Volume, we have plotted the Periodogram, and it doesn't seem like it has any pronounced power of frequency, this probably mean that the Volume of those stocks doesn't have any particular trend or stagionality, and if we connect this result to the PACF one, we can see that they both mean that our Values only have correlation with itself on the previous-day values, other than the fact that Volume seems really noisy.

For the other 4 values, we can see, that they all kinda share the same shape, and they also don't seem to have much of trends or stagionality, and the peaks we see in the graph are probably because of noise or small events that happened in that time period.

### Stationarity
To check the stationarity of the values in the dataset i decided to use the adfuller test, using a p-value of 0.1 instead of 0.05, to consider stationarity.<br>
From the results we can see that all the values are not-stationary with the usual exception of the Volume, which seems good, since the values in the volume are fluctuating around a consistent mean and variance.

## Model Creation
Given what we've found out about our data this far, i'm thinking of using three different models here:

- A hybrid model for open, close, high, low with a linear regression + xgboost (with multioutput from sklearn)
- A linear regression for the Volume

Both will be changed to have a lag 1, because of what we saw earlier.

### Open, High, Low, Close
To avoid overfitting here, in the XGBoost Regressor, i had it have a max_depth of 3, which is half the default, then reg_lambda and alpha set to 3 to have a balanced regularization, even with those, we can se in the results of the MSE, that the model tends to overfit, which confirms that using XGBRegressor may not be the best idea, so we'll just use the Linear Regression.
Seeing the results, we can see that during the training, it does have a slightly higher MSE, and still right under 3.0 for the test set, in this case, we could think that neither of our two tries meant overfitting, but more of a really noisy dataset, and considering that we're also using lag 1 as our features, we might even speculate the results are pretty good, too.

### Volume
For the Volume, i did the same things i had done for the previous features, then, seeing the output for the lienar regression, we can see from the MSE that the train has a slightly higher value than the test, this is a great thing because our data is noisy, as we've already stated. The high amount is not an error, but since we're looking at the Mean Squared Error, the values are similar to the actual raw values from the dataset (millions of actions, in this case)

## Results
In the end both of our Linear Regression seem adequate for our goal, if we wanted slightly better results we could've fix our raw data a bit by applying some filters like the rolling mean, or the kalman filter, but in this case it was already pretty good as a result.
