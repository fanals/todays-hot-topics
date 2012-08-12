define ['underscore', 'jquery'], () ->

    String.prototype.stripNonAlphaNum = ->
        this.toLowerCase().replace(/[^a-zA-Z0-9 ]+/g, '').replace(/\s+/g, ' ').trim()

    class topStories

        constructor : (@nbOfTopics, @pointsForAppearance, @pointsForRanking, @cb_done) ->
            TWITTER_FEED = 'https://api.twitter.com/1/trends/1.json'
            GOOGLE_FEED  = 'http://news.google.com/news?output=rss'
            YAHOO_FEED   = 'http://rss.news.yahoo.com/rss/topstories'
            XML_TO_JSON  = 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=8&q='

            # Where to find keyword topics ? In title of yahoo / google top stories and twitter trending !
            jsonFeeds =
                'google':
                    url: XML_TO_JSON+@encodeURL(GOOGLE_FEED)
                    getTitle: @getTitleGoogle
                'yahoo':
                    url: XML_TO_JSON+@encodeURL(YAHOO_FEED)
                    getTitle: @getTitleYahoo
                'twitter':
                    url: TWITTER_FEED
                    getTitle: @getTitleTwitter

            onSuccess = @cbClosure _.size(jsonFeeds), @findTopStories
            # Calls every api in jsonfeeds
            @apiCall value, onSuccess for own key, value of jsonFeeds

        scoringKeywords: (titles) ->
            # Gives points to topics depending on how many times they appears and in which order
            scoredKeywords = {}
            pointsForRanking = @pointsForRanking
            for title in titles
                keywords = title.split(' ')
                for keyword in keywords
                    continue if keyword.length <= 3
                    if scoredKeywords[keyword]
                        scoredKeywords[keyword] += pointsForRanking
                    else
                        scoredKeywords[keyword] = @pointsForAppearance + pointsForRanking
                pointsForRanking--
            scoredKeywords

        mergeDictionnaries: (arrayOfDictionnaries) ->
            # Merge the dictionnaries of topics and add points together for each topics that appears several times
            mergedDict = arrayOfDictionnaries[0]
            for dict in arrayOfDictionnaries[1..]
                for own keyword of dict
                    if mergedDict[keyword]
                        mergedDict[keyword] += dict[keyword]
                    else
                        mergedDict[keyword] = dict[keyword]
            mergedDict

        findTopStories: (scoredKeywordsArray) =>
            mergedScoredKeywords = @mergeDictionnaries scoredKeywordsArray
            res = []
            # Transforms the mergedDictionary with all topics and points to an ascending ordered array (by points) of topics
            _(mergedScoredKeywords).each(((v, k) -> if this[v] then this[v].push(k) else this[v] = [k]), res)
            topStories = []
            # Creates an array of objects (of @nbOfTopics max) with all topics that scored a maximum of points
            for i in [res.length - 1..0] by -1
                continue if not res[i]
                for story in res[i]
                    topStories.push({'name': story, 'points': i})
                    break if topStories.length >= @nbOfTopics
                break if topStories.length >= @nbOfTopics
            # Now we have our object of topics and points
            # We are done so time to call the callback and give it the topStories
            @cb_done(topStories)

        # Each json feeds from yahoo / google / twitter have a different way to store titles. 
        getTitleYahoo: (data) -> (el.title.stripNonAlphaNum() for el in data.responseData.feed.entries)
        getTitleGoogle: (data) -> (el.title.substr(0, el.title.lastIndexOf(' - ')).stripNonAlphaNum() for el in data.responseData.feed.entries)
        getTitleTwitter: (data) -> (el.name.stripNonAlphaNum() for el in data[0].trends when el.name[0] isnt '#')

        encodeURL: (url) ->
            encodedURL = ['']
            for l in url
                encodedURL.push(l.charCodeAt().toString(16))
            encodedURL.join('%')

        # Tricks to be able to call a function when all feeds have been loaded
        # See above in constructor
        cbClosure: (nb, cb) ->
            scoredKeywordsArray = []
            return (titles) =>
                scoredKeywordsArray.push(@scoringKeywords(titles))
                cb(scoredKeywordsArray) if not --nb

        # Do the API call
        apiCall: (feed, onSuccess) ->
            $.ajax feed.url,
                type: "GET"
                dataType: "jsonp",
                cache: false,
                success: (data) ->
                    onSuccess feed.getTitle data


