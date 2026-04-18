\# ML Model Files



This folder is used for local ML model artifacts required by the backend.



Large serialized model files such as `.pkl` and `.joblib` are intentionally excluded from version control due to repository size limits and portability concerns.



\## Expected local files



Place the required trained model files inside the appropriate subfolders before running prediction features locally.



Example:

\- `Random forest Regressor/hours\_remaining\_rf\_without\_mq.pkl`



\## Note



The application code expects these files to be present locally in this directory structure for prediction-related features.

