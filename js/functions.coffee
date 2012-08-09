$ ->
    String.prototype.stripNonAlphaNum = ->
        this.toLowerCase().replace(/[^a-zA-Z0-9 ]+/g, '').replace(/\s+/g, ' ').trim()

    scoringKeywords = (titles) ->
        scoredKeywords = {}
        pointsForAppearance = 15
        pointsForRanking = 10
        for title in titles
            keywords = title.split(' ')
            for keyword in keywords
                continue if keyword.length <= 3
                if scoredKeywords[keyword]
                    scoredKeywords[keyword] += pointsForRanking
                else
                    scoredKeywords[keyword] = pointsForAppearance + pointsForRanking
            pointsForRanking--
        scoredKeywords

    mergeDictionnaries = (arrayOfDictionnaries) ->
        mergedDict = arrayOfDictionnaries[0]
        for dict in arrayOfDictionnaries[1..]
            for own keyword of dict
                if mergedDict[keyword]
                    mergedDict[keyword] += dict[keyword]
                else
                    mergedDict[keyword] = dict[keyword]
        mergedDict

    displayTodaysHotTopics = (scoredKeywordsArray) ->
        mergedScoredKeywords = mergeDictionnaries scoredKeywordsArray
        res = {}
        _(mergedScoredKeywords).each(((v, k) -> if this[v] then this[v].push(k) else this[v] = [k]), res)
        console.log res

    getTitleYahoo = (data) -> (el.title.stripNonAlphaNum() for el in data.responseData.feed.entries)
    getTitleGoogle = (data) -> (el.title.substr(0, el.title.lastIndexOf(' - ')).stripNonAlphaNum() for el in data.responseData.feed.entries)
    getTitleTwitter = (data) -> (el.name.stripNonAlphaNum() for el in data[0].trends when el.name[0] isnt '#')

    cbClosure = (nb, cb) ->
        scoredKeywordsArray = []
        return (titles) ->
            scoredKeywordsArray.push(scoringKeywords(titles))
            cb(scoredKeywordsArray) if not --nb

    apiCall = (feed, onSuccess) ->
        $.ajax feed.url,
            type: "GET"
            dataType: "jsonp",
            cache: false,
            success: (data) ->
                onSuccess feed.getTitle data

    TWITTER_FEED = 'https://api.twitter.com/1/trends/1.json'
    GOOGLE_FEED  = 'http%3A%2F%2Fnews.google.com%2Fnews%3Foutput%3Drss'
    YAHOO_FEED   = 'http%3A%2F%2Frss.news.yahoo.com%2Frss%2Ftopstories'
    XML_TO_JSON  = 'http://ajax.googleapis.com/ajax/services/feed/load?v=1.0&num=8&q='

    jsonFeeds =
        'google':
            url: XML_TO_JSON+GOOGLE_FEED
            getTitle: getTitleGoogle
        'yahoo':
            url: XML_TO_JSON+YAHOO_FEED
            getTitle: getTitleYahoo
        'twitter':
            url: TWITTER_FEED
            getTitle: getTitleTwitter

    onSuccess = cbClosure _.size(jsonFeeds), displayTodaysHotTopics
    apiCall value, onSuccess for own key, value of jsonFeeds
