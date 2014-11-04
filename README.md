README.md
==========

_This information is under construction_

## Dependencies

[Tweepy](https://github.com/tweepy/tweepy) is needed in order to run the Python script. If you use Windows I recommend to download and install [setuptools]('https://pypi.python.org/pypi/setuptools') for Python first. Afterwards easy_install.exe is available in the "Scripts" subfolder of Python. Use the following command to install Tweepy: easy_install.exe tweepy. You can also download or fork the GitHub Tweepy master branch and copy the _"tweepy"_ subfolder to the realtimeR project folder / working directory.<br>
[requests](https://pypi.python.org/pypi/requests) is also needed in order to run the Python script. Use the following command to install: easy_install.exe requests.<br>
[requests_oauthlib](https://pypi.python.org/pypi/requests) is also needed in order to connect to Twitter using Python. Use the following command to install: easy_install.exe requests_oauthlib.<br>

## Scripts
* __streamkeywordsqlite.py__ is a Python script (v.2.x) which connects to the Twitter streaming API and creates an SQLite database. All new tweets from the realtime Twitter API are stored in the database, for further analysis with R.
* __twittercredentials.py__ is a Python script (v.2.x) in which you have to store your Twitter credentials. In order to get your Twitter credentials, visit the [Twitter Developers site](http://dev.twitter.com). In order to create a Twitter developers account, you need to click on the "Sign In" link at the top right of the Twitter page. Next, sign in with the Twitter account you want to associate with your app. Next, go to "Manage Your Apps". You will see all your registered Twitter apps. Now, create a New Application. Give your app a unique name (a name no one else has used for their Twitter app). Put your website in the website field, it will have no function but a website should be entered here. Ignore the Callback URL field. Make sure you read the "Developers Rules of the Road" text and check "Yes, I agree" and create your Twitter application. Now you can create your Access token. Click the "create my access token". This takes a couple of seconds and maybe you will have to refresh the page in order to see the access token on the next screen. Choose what Access Type you need. The default (read only) will do. Once you have done this, make a note of your OAuth settings. The ones you will need for twittercredentials.py are 
* _Consumer Key_ or _API Key_
* _Consumer Secret_ or _API Secret_
* _(OAuth) Access Token_
* _(OAuth) Access Token Secret_

You should keep these secret, if anybody else gets these keys your Twitter account can be compromised!

## Variables
Dataset variables (labels) are explained in [codeBook.md](https://github.com/digistam/realtimeR/blob/master/CodeBook.md).
