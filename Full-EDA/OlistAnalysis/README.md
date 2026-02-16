## Olist E-Commerce Project

The goal for this project is to explore how customers behave, delivery prediction and sentiment mismatch in reviews.

What i'll do in this project:
- SQL Data Engineering
- Delivery Time Prediction using XGBoost and SHAP for XAI
- Customer loyalty analysis
- Market basket Analysis using the FP-Growth algorithm
- NLP Sentiment vs Rating Mismatch using HuggingFace BERT and SHAP for XAI

## Informations

The Olist dataset is a collection of Datasets with data of 100k products in a time range of 2 years, from 2016 to 2018.

All data has been anonymized, for privacy reasons, with all companies and partners being replaced with the names of Game of Thrones great houses, as explained from the kaggle webpage: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce.

## Insight Spoilers
- In our Delivery Date Estimation notebook, we'll see how even with XGBoost, our prediction error stays around the 8.70 days, most likely due to missing features such as weather and traffic conditions.
- In our EDA Complete notebook, we find out that loyal customers are just 2.1% of total customers, and they make up for the 4.87% of total payment value.
- Using our Bert Classification model from hugging face, we'll see how even if rarely, our model can still mismatch predictions for high-rated reviews, most likely because they can contain "negative" words.

## Notebook 1, EDA Complete
In our SQL query (you can check it out in the main.sql file), we're using basic query functions like JOINS, WHERE conditions, views and CTE's, to create a complete dataset from the most important columns throughtout all the tables in our database.

After importing the final dataset in python, we can start by describing our features and analyzing what we're working with, to better understand clients interactions with Olist.

A few insights worth mentioning may be:
- Our Top 10 Product Categories by Payment Value, which shows that categories such as health beauty, bed bath tables and computer accessories, seems to heave a lead across all the other categories.
- Our Top 10 Product Categories by Reviews, that seems to back up the previous insight, leaving bed bath tables and health beauty at the top.
- Most people tend to pay using credit cards, and with a one-time payment, but we can see that few people can choose up to 10 months of payment, but none chooses 9 months, for some reason.
- Looking at the total customers, we see that the 2.1% of them is a returning client, and most of them returns at least once more. Despite this, loyal clients make up for the 4.87% of payment values.

Before looking at the NLP processing, we can also check out the correlations between categories of products using the FP-Growth alogrithm through the lift method, showing that the categories "furniture decor" and "bed bath table" seems to be at the center of the most most popular groups of categories people buy together.

### NLP for Reviews
For this, i've decided to group our reviews based on their star ratings, 1-3 stars are considered class 0, negative, meanwhile 4 and 5 stars are considered class 1, positive.

Since we turned this into a classification problem, we can simply use "BertForSequenceClassification" from the transformer library, specifically using "bert-base-multilingual-uncased".

If we check if our data is balanced, we won't be surprised seeing that 0.72% of the data is positive, and 0.27% is negative. Considering this, i've considered using a custom class weight for our loss, which turned out great if we now look at the result of our total-fine-tuning, that shows a Test Loss of 0.2899 at the end of a 5 epoch training.

Our classification report shows that the model did learn a lot and was able to adapt greatly to our data, showing a 0.89% accuracy and 0.90/0.89 recall.

But now we want to know what made our Bert classifier decide like this, so i've created a quick confusion matrix, that showed that the model actually mismatched around 1144 False Negatives, and 369 False Positives, let's look further into it using the SHAP library.

### False Negatives
If we look into the false negatives specifically, we can see our bar plot showing most of the features leaning towards the negative class, and neutral words like "Come" leaning towards the positive class (colored red), but overall the model seems to understand that most words are negative, leading to false negatives when the review is actually positive.

### False Positives
Now, if we look for the false positives, which are only 369, we can see that the model sees all the most important words as leaning towards the negative class (in blue) with very few words leaning towards the positive class.

### Result
With this analysis, we can see that even if a review has positive rating, if the clients speaks with mostly negative words, the model will predict it as negative, and vice versa. This shows how models can be sensitives to individual words polarity rather than the overall sentiment.

## Notebook 2, Delivery Date Estimation
This second notebook is specifically made to understand how precise we can be in the estimation date.

After importing our SQL query result into python, the first thing i did was to analyze which features are most correlated with our "delivery days" target, using a heatmap we can se that correlations are weaker than expected, most likely due to missing data, such as holidays, but we can still work with the result.

One insight worth mentioning is for the package related features, we can see that the boxplot's IQR is very small, and most of the graph is actually made of outliers, but since we're speaking about packages, it's not unexpected, and our model won't really mind the range of features, in this case.

### Firt XGBoost
Our objective is to predict the number of days for delivery. For this model, we're going to use the "squared error" loss. To evaluate our results, we're reporting the RMSE, which gives us how many days the model is wrong generally, in this case, it's 8.51 days.

To understand why we're getting this amount of error, we're printing the plot_importance from the XGBoost library itself, which shows us that the customer latitude and longitude are the most important features in order to get the distance, along with the seller coordinates and the summed freight value.

With this we can see that the model successfully understood that the 2D travel coordinates are the most relevant part for delivery and the other features like the freight value and package features are still important, but mostly won't impact much on the amount of days.

### Second XGBoost
Looking at the first model, we saw that it successfully understood the 2D coordinates, but what if we gave the model the number of kilometers and the day of the week the customer bought the item?
Looking at the result, we see that the RMSE increased to 8.70 days, not a lot of difference compared to our firt model.

If we analyze the feature importance for this model, of course the number of kilometers is the highest, but now, the model actually way more interested in the packages features, and the day of the week doesn't seem to give much influence.

### Comparing both models with SHAP
Looking at the summary plots for both models, we can see that the coordinates and kilometers tend to have less shap value, but the other features are always around the 0 point, showing that both models aren't much influenced by them, but are still important in the decision.

In the first model, we're also inspecting how latitude and longitude are interacting with one another, and we can see the lower values for the longitude seem to anchor the latitude towards the 0 point, meaning that despite the latitude alone would increase the predicted estimation date, lower values of longitude seems to make the model understand that each area tends to have their own group of estimation date ranges, most likely due to terrain, traffic and other unknown variables to us.

I have also tried to understand dependency for other variables for both models, such as weight and kilometers, but in both cases, statistically speaking, no other feature is directly depending on them, showing us cases of spurious correlations for a third variable we don't have.

Finally, if we look for a specific case in both models using the waterfall plot, we can see exactly how each model is thinking, showing in blue, all the features that tend to lower the amount of days predicted, and in red the ones that increase.

For the first model, the seller latitude seems to decrease the amount of days, but as we saw earlier, the customer latitude tends to increase the days, other variables seems to be balanced with one another, giving us the result of 10,5 days.

For the second model, most features seems to lower the amount of days, but apparently package-specific features such as width and height, tends to increase the result.

# Key Learnings
This project was a valuable exercise with real-world data, and it also showed me that even the smallest details or changes, are actually really important for businesses such as Olist.

The approach i've used in both notebooks shows why feature engineering, model selection and interpretability techniques are crucial to better understand and improve our predictive performance and approach in real world situations.