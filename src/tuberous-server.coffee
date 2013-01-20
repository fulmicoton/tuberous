potato = require 'potato'
mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID
assert = require 'assert'
async = require 'async'

db = null
server = null

close = (cb)->
    db.close true, (error, data)->
        db = undefined
        server = undefined
        cb error,data

configure = (config, cb=(->))->
    if server?
        db.close()
        db = undefined
        server = undefined
    server = new mongodb.Server config.host, config.port, auto_reconnect: true
    db = new mongodb.Db(config.db, server, {})
    cb()

setup = (callback)->
    if not module.client?
        db.open (error, client)->
          if error
            console.log "Couldn't open connection to MongoDB."
            throw error
          else
            console.log "Connected to mongodb."
            module.client = client
            callback()
    else
        callback()


MongoID = potato.Literal
    type: 'string'
    default: mongodb.ObjectID
    make: (val)->
        if val?
            @set val
        else
            potato.pick  @default
    fromData: (val)->
        new mongodb.ObjectID val
    setData: (obj,val)->
        @set obj, val
    toData: (val)->
        val
    set: (obj,val)->
        if typeof val == 'object'
            val
        else
            @fromData val
    makeFromData: (data)->
        new mongodb.ObjectID data


Date = potato.Literal
    default: -> new Date()

ForeignObject = (ForeignType)-> potato.Model
    static:
        ForeignType: ForeignType
        
    components:
        foreignKey: MongoID

    methods:
        toData: ->
            MongoID.toData @foreignKey
        
        setData: (foreignKey)->
            @foreignKey = MongoID.setData @foreignKey, foreignKey
            this

        fetch: (cb)->
            @__potato__.ForeignType.findById @foreignKey, cb

Model = potato.Model
    
    static:
        CONFIG:
            safe: true
            multi:false
            upsert:true 
        MAX_PER_REQUEST: 10
        indexes: [] 

        collectionName: ->
            throw "Not Implemented."

        loadFixtures: (datas, cb)->
            fixtures = []
            for data in datas 
                do (data)=>
                    fixtures.push (cb)=>
                        console.log "*", data
                        obj = @make()
                        obj.setData data
                        obj.save cb
            async.series fixtures, cb

        ensureIndex: (callback=(->))->
            collectionName = potato.pick @collectionName
            potato.log "Ensuring indexes for #{ collectionName }"
            collection = @collection()
            ensureOneIndex = (index,callback)->
                collection.ensureIndex(index, callback)
            async.map @indexes, ensureOneIndex, (results)->callback()

        collection: ->
            collectionName = potato.pick @collectionName
            new mongodb.Collection db, collectionName


        findById: (itemId, callback)->
            if (typeof itemId == "string")
                itemId = ObjectID itemId
            filter = {_id: itemId}
            @collection().findOne filter, (err, data)=>
                if err?
                    callback err, data
                else if data?
                    callback err, @fromData data
                else
                    callback err, null

        findOne: (filter, callback)->
            assert.ok typeof filter == "object"
            @collection().findOne filter, callback

        find: (filter, callback, limit = @MAX_PER_REQUEST)->
            assert.ok typeof filter == "object"
            @collection().find(filter).limit(limit).toArray callback
    
    components:
        _id: MongoID

    methods:
        save: (cb, config=undefined)->
            config = potato.rextend @__potato__.CONFIG, config
            data = @toData()
            if @_id?
                data._id = @_id
            collection = @__potato__.collection()
            collection.save data, config, cb

module.exports =
    configure: configure
    close: close
    ForeignObject: ForeignObject
    Model: Model
    Date: Date
    MongoID: MongoID
