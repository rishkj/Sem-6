import flask
from flask import Flask, render_template,jsonify,request,abort,Response
from flask_sqlalchemy import SQLAlchemy
import requests
import json
from datetime import datetime
import re
import csv

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////app/test.db'
db = SQLAlchemy(app)


class Ride(db.Model):
    __tablename__ = 'ride'
    ride_id = db.Column(db.Integer, primary_key = True)
    source = db.Column(db.Integer, nullable = False)
    destination = db.Column(db.Integer, nullable = False)
    timestamp = db.Column(db.String(80), unique = False, nullable = False)
    creator_name = db.Column(db.String(80), unique = False, nullable = False)

class Users_and_Rides(db.Model):
    __tablename__ = 'users_and_rides'
    id = db.Column(db.Integer, primary_key = True)
    ride_id = db.Column(db.Integer, nullable = False)
    username = db.Column(db.String(80), nullable = False)


db.create_all()

areas = dict()
with open('AreaNameEnum.csv') as f:
        dets = csv.reader(f,delimiter = ',')
        line_count = 0
        for row in dets:
                if(line_count==0):
                        line_count+=1
                else:
                        areas[int(row[0])] = row[1]


tv = re.compile(r'\d{2}-\d{2}-\d{4}:\d{2}-\d{2}-\d{2}')

url_get_users = 'http://user_call:5000/api/v1/users'

url_read_rides = 'http://ride_call:5000/api/v1/db/read'
url_write_rides = 'http://ride_call:5000/api/v1/db/write'



@app.route('/api/v1/rides',methods=['POST'])
def new_ride():
    try:
        data = flask.request.json
        id_creator = data['created_by']
        timestamp = data['timestamp']
        source = int(data['source'])
        dest = int(data['destination'])

        if not tv.match(timestamp):
            return Response("Timestamp entered in invalid format",status = 400)
        
        now = datetime.now()

        ride_date = datetime.strptime(timestamp, '%d-%m-%Y:%S-%M-%H')
        if ride_date < now:
            return Response("Can't creade ride with a timestamp that has already passed",status = 400)
        
        if source == dest:
            return Response("Source and destination are same",status = 400)

        if(source not in areas.keys() or dest not in areas.keys()):
            ressd = False
        else:
            ressd = True

        user_list = requests.get(url_get_users)
        user_list = json.loads(user_list.text)
        user_list = user_list['list']

        resu = False
        if len(user_list) != 0:
            for i in user_list:
                if i == id_creator:
                    resu = True
                    break
    
        else:
            resu = False

        if ressd and resu:
            ride_dict = {"table" : "ride", "method" : "POST", "created_by" : id_creator, "timestamp" : timestamp, "source" : source, "destination" : dest}
            ride_json = json.dumps(ride_dict)

            requests.post(url_write_rides,json = ride_json)

            return jsonify({}),201
        
        else:
            if not resu:
                return Response("No such user exists",status = 400)
            else:
                return Response("Source or destination invalid",status = 400)
    
    except:
        return Response("Error while providing data",status = 400)


@app.route('/api/v1/rides',methods=['GET'])
def upcoming_rides():
    try:
        source = int(request.args.get('source'))
        destination = int(request.args.get('destination'))
        
        if source not in areas.keys() or destination not in areas.keys():
            return Response("Source or destination invalid",status = 400)
        
        else:
            ride_dict = {"table" : "ride", "method" : "GET", "source" : source, "destination" : destination}
            ride_json = json.dumps(ride_dict)

            ride_results = requests.post(url_read_rides,json = ride_json)
            ride_results = json.loads(ride_results.text)

            if not ride_results:
                return jsonify({}),204
            
            else:
                now = datetime.now()

                l = []

                for i in ride_results.keys():
                    ride_date = ride_results[i]['timestamp']
                    ride_date = datetime.strptime(ride_date, '%d-%m-%Y:%S-%M-%H')

                    if ride_date >= now:
                        l.append(ride_results[i])
                
                if len(l) == 0:
                    return jsonify({}),204
                
                else:
                    return jsonify(l)
        
    except:
        return Response("Error while providing data",status = 400)



@app.route('/api/v1/rides/<ride_id>',methods=['GET'])
def details(ride_id):
    try:
        ride_id = int(ride_id)
        ride_dict = {"table" : "ride and users_and_rides", "method" : "GET", "ride_id" : ride_id}
        ride_json = json.dumps(ride_dict)

        ride_results = requests.post(url_read_rides,json = ride_json)
        ride_results = json.loads(ride_results.text)
        
        if ride_results['empty'] == 1:
            return jsonify({}),204
        else:
            del ride_results['empty']
            
            return jsonify(ride_results)
    
    except:
        return Response("Error while providing data",status = 400)


@app.route('/api/v1/rides/<ride_id>',methods=['POST'])
def join_existing_ride(ride_id):
    try:
        ride_id = int(ride_id)
        data = flask.request.json
        username = data['username']

        ride_dict = {"table" : "ride", "method" : "POST", "ride_id" : ride_id}
        ride_json = json.dumps(ride_dict)

        ride_results = requests.post(url_read_rides,json = ride_json)
        ride_results = json.loads(ride_results.text)

        user_list = requests.get(url_get_users)
        user_list = json.loads(user_list.text)
        user_list = user_list['list']



        if username not in user_list:
            return Response("No user with that username exists",status = 400)
        
        else:
            if ride_results['empty'] == 1:
                return Response("No ride with that id exists",status = 400)
            
            else:
                ride_date = ride_results['timestamp']
                now = datetime.now()
                ride_date = datetime.strptime(ride_date, '%d-%m-%Y:%S-%M-%H')

                if ride_date < now:
                    return Response("Ride has already expired",status = 400)

                if ride_results['ride_creator'] == username:
                    return Response("This user has created the ride",status = 400)

                elif username in ride_results['users_joined']:
                    return Response("This user has already joined ride",status = 400)

                else:
                    user_joining_dict = {"table" : "users_and_rides", "method" : "POST", "ride_id" : ride_id, "username" : username}
                    user_joining_json = json.dumps(user_joining_dict)

                    requests.post(url_write_rides,json = user_joining_json)

                    return jsonify({}),200
    except:
        return Response("Error while providing data",status = 400)


@app.route('/api/v1/rides/<ride_id>',methods=['DELETE'])
def delete_ride(ride_id):
    try:
        ride_id = int(ride_id)
        ride_dict = {"table" : "ride", "method" : "DELETE", "ride_id" : ride_id}
        ride_json = json.dumps(ride_dict)

        ride_results = requests.post(url_read_rides,json = ride_json)
        ride_results = json.loads(ride_results.text)

        if ride_results['empty'] == 1:
            return Response("No ride with that ride_id exists",status = 400)
        
        else:
            ride_and_users_dict = {"table" : "ride", "method" : "DELETE", "ride_id" : ride_id}
            ride_and_users_json = json.dumps(ride_and_users_dict)

            requests.post(url_write_rides,json = ride_and_users_json)

            return jsonify({}),200
    except:
        return Response(status = 400)



@app.route('/api/v1/db/write',methods=['POST'])
def db_write():
    data = flask.request.json
    data = json.loads(data)
    table_chosen = data['table']
    method_used = data['method']


    if table_chosen == "user":
        if method_used == "DELETE":
            username = data['username']

            rides_joined = Users_and_Rides.query.filter_by(username = username).all()

            if len(rides_joined) != 0:
                for i in rides_joined:
                    db.session.delete(i)
                    db.session.commit()
            
            return "Deleted"
    
    elif table_chosen == "ride":
        if method_used == "POST":
            ride_creator_username = data['created_by']
            timestamp = data['timestamp']
            source = data['source']
            dest = data['destination']

            new_ride = Ride(source = source, destination = dest,timestamp = timestamp, creator_name = ride_creator_username)
            db.session.add(new_ride)
            db.session.commit()

            return "Added"
        
        elif method_used == "DELETE":
            ride_id = data['ride_id']

            ride_dets = Ride.query.filter_by(ride_id = ride_id).first()
            db.session.delete(ride_dets)
            db.session.commit()

            users_joined = Users_and_Rides.query.filter_by(ride_id = ride_id).all()
            if len(users_joined) !=0:
                for i in users_joined:
                    db.session.delete(i)
                    db.session.commit()
            
            return "Deleted"
    
    elif table_chosen == "users_and_rides":
        if method_used == "POST":
            ride_id = data['ride_id']
            username = data['username']

            new_user_joined = Users_and_Rides(ride_id = ride_id,username = username)
            db.session.add(new_user_joined)
            db.session.commit()

            return "Added"


@app.route('/api/v1/db/read',methods=['POST'])
def db_read():
    data = flask.request.json
    data = json.loads(data)
    table_chosen = data['table']
    method_used = data['method']
    
    
    if table_chosen == "ride":
        if method_used == "GET":
            source = data['source']
            dest = data['destination']

            all_rides = Ride.query.filter_by(source = source, destination = dest).all()

            count = 0
            ride_details = dict()
            for i in all_rides:
                ride_details[count] = dict()
                ride_details[count]["rideId"] = i.ride_id
                ride_details[count]["username"] = i.creator_name
                ride_details[count]["timestamp"] = i.timestamp

                count += 1

            return json.dumps(ride_details)
        
        elif method_used == "POST":
            ride_id = data['ride_id']

            ride_details = dict()
            req_ride = Ride.query.filter_by(ride_id = ride_id).first()
            
            if req_ride is None:
                ride_details["empty"] = 1

            else:
                ride_details["empty"] = 0
                ride_details["ride_creator"] = req_ride.creator_name
                ride_details["users_joined"] = []
                ride_details["timestamp"] = req_ride.timestamp

                users_joined = Users_and_Rides.query.filter_by(ride_id = ride_id).all()
                for i in users_joined:
                    ride_details["users_joined"].append(i.username)

            return json.dumps(ride_details)

        elif method_used == "DELETE":
            ride_id = data['ride_id']

            ride_details = dict()
            req_ride = Ride.query.filter_by(ride_id = ride_id).first()

            if req_ride is None:
                ride_details["empty"] = 1

            else:
                ride_details["empty"] = 0
            return json.dumps(ride_details)

    elif table_chosen == "ride and users_and_rides":
        if method_used == "GET":
            ride_id = data['ride_id']

            req_ride = Ride.query.filter_by(ride_id = ride_id).first()

            ride_details = dict()
            if req_ride is None:
                ride_details["empty"] = 1
                return json.dumps(ride_details)
            
            else:
                ride_details["empty"] = 0
                ride_details["rideId"] = ride_id
                ride_details["created_by"] = req_ride.creator_name
                ride_details["users"] = []
                ride_details["timestamp"] = req_ride.timestamp
                ride_details["source"] = req_ride.source
                ride_details["destination"] = req_ride.destination

                users_joined = Users_and_Rides.query.filter_by(ride_id = ride_id).all()
                for i in users_joined:
                    ride_details["users"].append(i.username)
                
                return json.dumps(ride_details)

    elif table_chosen == "user":
        if method_used == "DELETE":
            username = data['username']
            ride_check = Ride.query.filter_by(creator_name = username).all()
            user_with_ride = dict()
            if len(ride_check) == 0:
                user_with_ride['empty'] = 1
            else:
                user_with_ride['empty'] = 0
            return json.dumps(user_with_ride)


@app.route('/api/v1/db/clear',methods=['POST'])
def clear_db():
    rides_list = Ride.query.all()

    res_del = False

    if(len(rides_list) != 0):
        for i in rides_list:
            db.session.delete(i)
            db.session.commit()

        res_del = True
    
    users_joined_rides = Users_and_Rides.query.all()

    if(len(users_joined_rides) != 0):
        for i in users_joined_rides:
            db.session.delete(i)
            db.session.commit()

        res_del = True
    
    if res_del:
        return jsonify({}),200
    
    else:
        return jsonify({}),200



if __name__=="__main__":
        app.run(host = '0.0.0.0')
