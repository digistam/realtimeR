#!/usr/bin/env python
# -*- coding: utf-8 -*-
# © 2014, Mark Stam 

# twitter client
import tweepy
import twittercredentials
import trackWords
import sys

# database interface
import sqlite3
conn = sqlite3.connect(trackWords.DATABASE)
conn.text_factory = str
curs = conn.cursor()
keyword = trackWords.KEYWORD
trackWords = trackWords.LIST

table = "CREATE TABLE IF NOT EXISTS " + keyword + " (id INTEGER PRIMARY KEY AUTOINCREMENT, tid TEXT, username TEXT, \
        statuses TEXT, since TEXT, followers INTEGER, friends INTEGER, location TEXT, utc_offset INTEGER, \
        created_at DATETIME, content TEXT, geo TEXT, meta TEXT, hashtags TEXT, urls TEXT, media TEXT, source TEXT, lang TEXT)"
curs.execute(table)

class StreamWatcherHandler(tweepy.StreamListener):
    """ Handles all incoming tweets as discrete tweet objects.
    """

    
    def on_status(self, status):
        """Called when status (tweet) object received.

        See the following link for more information:

        https://github.com/tweepy/tweepy/blob/master/tweepy/models.py

        """
        try:
            # helper functions

            def geoparser(x):
               return ["%s" % str(item).encode('utf-8').strip() for item in x]
            
            def hashtagparser(x):
               return [item['text'].encode('utf-8').strip() for item in x]

            def urlparser(x):
               return [str(item['expanded_url']).encode('utf-8').strip() for item in x]

            def mediaparser(x):
               return [str(item['media_url']).encode('utf-8').strip() for item in x]

            tid = status.id_str
            usr = status.author.screen_name.encode('utf-8').strip()
            try:
                statuses = status.user.statuses_count
            except KeyError:
                statuses = ''
            try:
                since = status.user.created_at
            except KeyError:
                since = ''
            try:
                followers = status.user.followers_count
            except KeyError:
                followers = ''
            try:
                friends = status.user.friends_count
            except KeyError:
                friends = ''
            try:
                location = status.user.location
            except KeyError:
                location = ''
            try:
                utc_offset = status.user.utc_offset
            except KeyError:
                utc_offset = ''
            txt = status.text.encode('utf-8').strip()
            cat = status.created_at
            if str(status.geo) != 'None':
                geo = geoparser(status.geo['coordinates'])
            else:
                geo = ''
            meta = str(status.entities).encode('utf-8')
            hasht = hashtagparser(status.entities['hashtags'])
            urls = urlparser(status.entities['urls'])
            try:
                media = mediaparser(status.entities['media'])
            except KeyError:
                media = ''
            src = status.source.encode('utf-8').strip()
            lang = status.lang

            # Now that we have our tweet information, let's stow it away in our 
            # sqlite database
            curs.execute("insert into " + keyword + " (tid, username, \
                            statuses, since, followers, friends, location, utc_offset, \
                            created_at, content, geo, meta, hashtags, urls, media, source, lang) \
                          values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",         \
                          (tid, usr, statuses, since, followers, friends, location, utc_offset, \
                           cat, txt, ', '.join(geo), meta, ', '.join(hasht), ', '.join(urls),\
                           ', '.join(media), src, lang))
            conn.commit()
        except Exception as e:
            # Most errors we're going to see relate to the handling of UTF-8 messages (sorry)
            print(e)

    def on_error(self, status_code):
       print('An error has occured! Status code = %s' % status_code)
       return True

def main():
    # establish stream
    consumer_key = twittercredentials.CONSUMER_KEY
    consumer_secret = twittercredentials.CONSUMER_SECRET
    auth1 = tweepy.auth.OAuthHandler(consumer_key, consumer_secret)

    access_token = twittercredentials.ACCESS_KEY
    access_token_secret = twittercredentials.ACCESS_SECRET
    auth1.set_access_token(access_token, access_token_secret)
    while True:
        try:
            print "Establishing stream...",
            stream = tweepy.Stream(auth1, StreamWatcherHandler(), timeout=None)
            #stream.filter(track=[keyword])
            stream.filter(track=trackWords )
            print "Done"
        except:
            e = sys.exc_info()[0]
            print(e)
            continue
        
    # Start pulling our sample streaming API from Twitter to be handled by StreamWatcherHandler
    #stream.sample()
    stream.filter(track=['global'])

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print "Disconnecting from database... ",
        conn.commit()
        conn.close()
        print "Done"
