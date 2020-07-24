import flask
from flask import Flask, render_template,jsonify,request,abort,Response
from flask_sqlalchemy import SQLAlchemy
import requests
import json
from datetime import datetime
import re

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////app/test.db'
db = SQLAlchemy(app)


class User(db.Model):
    __tablename__ = 'user'
    username = db.Column(db.String(80), primary_key = True)
    password = db.Column(db.String(40), unique = False, nullable = False)


db.create_all()

hex_digits = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']

url_read_users = 'http://user_call:5000/api/v1/db/read'
url_write_users = 'http://user_call:5000/api/v1/db/write'

url_read_rides = 'http://Users-Rides-1846279167.us-east-1.elb.amazonaws.com/api/v1/db/read'
url_write_rides = 'http://Users-Rides-1846279167.us-east-1.elb.amazonaws.com/api/v1/db/write'


def validate_password(password):
    if( len(password) != 40):
        return False
    else:
        for i in password:
            j = i.lower()
            if j not in hex_digits:
                return False
        return True


@app.before_request
def increase_count():
    if '/api/v1/users' in request.path:
        data = {}
        with open('count.txt','r') as file_count:
            data = json.load(file_count)
            data['count'] += 1

        with open('count.txt','w') as file_count:
            json.dump(data,file_count)


@app.route('/api/v1/users',methods=['PUT'])
def add_user():
    try:
        data = flask.request.json
        user_name = data["username"]
        password = data["password"]

        user_dict = { "table" : "user", "method": "PUT", "username": user_name }
        user_json = json.dumps(user_dict)

        user_results = requests.post(url_read_users,json = user_json)
        user_results = json.loads(user_results.text)

        if user_results['empty'] == 1:
            resu = True
        else:
            resu = False
        resp = validate_password(password)

        if resu and resp:
            user_dict = { "table" : "user", "method" : "PUT", "username" : user_name , "password" : password}
            user_json = json.dumps(user_dict)

            requests.post(url_write_users,json = user_json)
            print("1")
            print(User.query.filter_by(username = user_name).all())

            return Response(status = 201)

        else:
            if not resu:
                return Response("Username already exists",status = 400)
            else:
                return Response("Password is not allowed",status = 400)
    
    except:
        return Response("Error while providing data",status = 400)

    

@app.route('/api/v1/users/<username>',methods=['DELETE'])
def remove_user(username):
    try:
        user_dict = {"table" : "user", "method" : "DELETE", "username" : username}
        user_json = json.dumps(user_dict)

        user_results = requests.post(url_read_users,json = user_json)
        user_results = json.loads(user_results.text)

        if user_results['empty'] == 1:
            return Response("No such user exists",status = 400)
        
        else:
            # Place a call to other container to check if user has created a ride
            user_dict = {"table" : "user", "method" : "DELETE", "username" : username}
            user_json = json.dumps(user_dict)

            user_results = requests.post(url_read_rides,json = user_json)
            user_results = json.loads(user_results.text)
            
            if user_results['empty'] == 0:
                return Response("User is associated with ride, cant be deleted",status = 400)

            else:
                user_dict = { "table" : "user", "method" : "DELETE", "username" : username}
                user_json = json.dumps(user_dict)
                requests.post(url_write_users,json = user_json)

                print(User.query.all())
                
                return jsonify({}),200
    
    except:
        return Response(status = 400)



@app.route('/api/v1/users',methods=['GET'])
def list_all_users():
    try:
        user_dict = {"table" : "user", "method" : "GET"}
        user_json = json.dumps(user_dict)

        user_results = requests.post(url_read_users,json = user_json)
        user_results = json.loads(user_results.text)

        return jsonify(user_results)

    except:
        return Response(status = 400)


@app.route('/api/v1/db/write',methods=['POST'])
def db_write():
    data = flask.request.json
    data = json.loads(data)
    table_chosen = data['table']
    method_used = data['method']

    if table_chosen == "user":
        if method_used == "PUT":
            user_name = data['username']
            password = data['password']
            new_user = User(username = user_name,password = password)
            db.session.add(new_user)
            db.session.commit()
            return "Added"

        elif method_used == "DELETE":
            user_name = data['username']

            user_being_removed = User.query.filter_by(username = user_name).first()

            db.session.delete(user_being_removed)
            db.session.commit()

            user_dict = {"table" : "user", "method" : "DELETE", "username" : user_name}
            user_json = json.dumps(user_dict)

            requests.post(url_write_rides,json = user_json)

            return "Deleted"


@app.route('/api/v1/db/read',methods=['POST'])
def db_read():
    data = flask.request.json
    data = json.loads(data)
    table_chosen = data['table']
    method_used = data['method']

    if table_chosen == "user":
        if method_used == 'PUT' or method_used == 'DELETE':
            user_name = data['username']
            username_checking = User.query.filter_by(username = user_name).first()
        
            user_details = dict()

            if username_checking is None:
                user_details["empty"] = 1

            else:
                user_details["empty"] = 0
            
            return json.dumps(user_details)

        elif method_used == 'GET':
            username_list = User.query.all()
            user_details = dict()

            user_details["list"] = []

            for i in username_list:
                user_details['list'].append(i.username)
            
            return json.dumps(user_details)



@app.route('/api/v1/db/clear',methods=['POST'])
def clear_db():
    user_list = User.query.all()

    if(len(user_list) != 0):
        for i in user_list:
            db.session.delete(i)
            db.session.commit()

        return jsonify({}),200


@app.route('/api/v1/_count',methods=['GET'])
def count_requsts():
    try:
        data = {}
        with open('count.txt','r') as file_count:
            data = json.load(file_count)

        l = [data['count']]
        return jsonify(l),200
    except:
        return Response(status = 400)


@app.route('/api/v1/_count',methods=['DELETE'])
def reset_request():
    try:
        data = {}
        with open('count.txt','r') as file_count:
            data = json.load(file_count)
            data['count'] = 0

        with open('count.txt','w') as file_count:
            json.dump(data,file_count)


        return jsonify({}),200
    except:
        return Response(status = 400)
    

if __name__=="__main__":
        app.run(host = '0.0.0.0')