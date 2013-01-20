potato = require 'potato'
db = require './db'
mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID
assert = require 'assert'
async = require 'async'

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
            db.collection collectionName

        findById: (itemId, callback)->
            if (typeof itemId == "string")
                itemId = ObjectID itemId
            @collection().findOne {_id: itemId}, (err, data)=>
                if err?
                    callback err, data
                else
                    callback err, @fromData data

        findOne: (filter, callback)->
            assert.ok typeof filter == "object"
            @collection().findOne filter, callback

        find: (filter, callback, limit = @MAX_PER_REQUEST)->
            assert.ok typeof filter == "object"
            @collection().find(filter).limit(limit).toArray callback
    
    components:
        _id: MongoID

    methods:
        save: (callback)->
            data = @toData()
            if @_id?
                data._id = @_id
            @__potato__.collection().save data, {safe: true, multi:false, upsert:true}, callback

Date = potato.Literal
    default: -> new Date()

module.exports = 
    ForeignObject: ForeignObject
    Model: Model
    Date: Date
    MongoID: MongoID
