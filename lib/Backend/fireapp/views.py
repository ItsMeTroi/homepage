import asyncio
import datetime
import os
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.views.decorators.csrf import csrf_exempt
import pyrebase
from django.conf import settings

config = {
    "apiKey": "AIzaSyDw9O_eTCyy-Poxm9OeatzVqeYDUFZAzDo",
    "authDomain": "tests-c91d0.firebaseapp.com",
     "databaseURL": "https://tests-c91d0-default-rtdb.firebaseio.com/",
    "projectId": "tests-c91d0",
    "storageBucket": "tests-c91d0.appspot.com",
    "messagingSenderId": "252862784800",
    "appId": "1:252862784800:web:b7de3c3653933bf39c6345",
    "measurementId": "G-FXCE602VES"
}

firebase=pyrebase.initialize_app(config)
authe = firebase.auth()
database=firebase.database()

@api_view(['POST'])
@csrf_exempt
def register(request):
    if request.method == 'POST':
        username = request.data.get('username')
        email = request.data.get('email')  # get email from request
        password = request.data.get('password')
        confirm_password = request.data.get('confirm_password')
        firstname = request.data.get('firstname')  # get first name from request
        lastname = request.data.get('lastname')  # get last name from request

        if password != confirm_password:
            error_message = "Passwords do not match."
            return Response({'error_message': error_message}, status=400)

        try:
            # Create the user with the provided email and password
            user = authe.create_user_with_email_and_password(email, password)

            # Save the registered user in the Realtime Database
            data = {
                'username': username,
                'email': email,  # also save email
                'firstname': firstname,  # save first name
                'lastname': lastname,  # save last name
                'is_manager': False,  # set is_manager to False by default
                'is_organizer': False,
            }
            database.child('users').child(user['localId']).set(data)

            # Return a success response
            return Response({'message': 'Registration successful'})
        except Exception as e:
            # Handle registration errors and return an appropriate response
            error_message = str(e)
            return Response({'error_message': error_message}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)



@api_view(['POST'])
@csrf_exempt
def login(request):
    if request.method == 'POST':
        email_from_request = request.data.get('email')  # Use a different variable name here

        # Fetch the email, firstname, lastname, and username associated with this email from the database
        users = database.child('users').get()
        email = None
        firstname = None
        lastname = None
        local_id = None
        is_manager = False
        username = None  # Initialize the username variable

        for user in users.each():
            if user.val()['email'] == email_from_request:  # Use the new variable here
                firstname = user.val().get('firstname', '')
                lastname = user.val().get('lastname', '')
                is_manager = user.val().get('is_manager', False)
                username = user.val().get('username', '')  # Get the username from the database
                local_id = user.key()
                break

        if email_from_request is None:
            return Response({'error_message': 'Invalid email'}, status=status.HTTP_400_BAD_REQUEST)

        password = request.data.get('password')

        try:
            # Perform the login process
            user = authe.sign_in_with_email_and_password(email_from_request, password)

            # Return the username, localId, firstname, lastname, and is_manager along with the success response
            return Response({
                'message': 'Login successful',
                'email': email_from_request,
                'localId': local_id,
                'firstname': firstname,
                'lastname': lastname,
                'username': username,  # Include the username in the response
                'is_manager': is_manager
            })
        except Exception as e:
            # Handle login errors and return an appropriate response
            error_message = str(e)
            return Response({'error_message': error_message}, status=status.HTTP_400_BAD_REQUEST)

    return Response({'error_message': 'Invalid request'}, status=status.HTTP_400_BAD_REQUEST)




@api_view(['GET'])
@csrf_exempt
def current_user(request):
    if request.method == 'GET':
        # Get the user's token from the request headers
        token = request.headers.get('Authorization')

        if not token:
            # Return an error response if the token is missing
            return Response({'error_message': 'Authorization header missing'}, status=401)

        try:
            # Verify the token and get user information
            user_info = authe.get_account_info(token)

            # Get user ID
            user_id = user_info['users'][0]['localId']

            # Fetch the user's data from the database
            user_data = database.child('users').child(user_id).get().val()

            # If the user data is None, it means the user doesn't exist in the database
            if not user_data:
                return Response({'error_message': 'User not found in the database'}, status=404)

            # Get the firstname and lastname
            firstname = user_data.get('firstname', '')
            lastname = user_data.get('lastname', '')

            # Return the firstname and lastname
            return Response({'firstname': firstname, 'lastname': lastname})
        except Exception as e:
            # Handle errors and return an appropriate response
            error_message = str(e)
            return Response({'error_message': error_message}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)






@api_view(['GET'])
@csrf_exempt
def get_all_users(request):
    if request.method == 'GET':
        try:
            # Fetch all users from the database
            users = database.child('users').get()

            # Prepare the users data
            users_data = []
            for user in users.each():
                user_data = user.val()
                user_data['id'] = user.key()
                users_data.append(user_data)

            # Return the users data
            return Response(users_data)

        except Exception as e:
            # Handle errors and return an appropriate response
            error_message = str(e)
            return Response({'error_message': error_message}, status=500)

    return Response({'error_message': 'Invalid request'}, status=400)

@api_view(['POST'])
@csrf_exempt
def create_team(request):
    if request.method == 'POST':
        manager_id = request.data.get('manager_id')
        team_name = request.data.get('team_name')
        game = request.data.get('game')

        try:
            user_data = database.child('users').child(manager_id).get().val()
            if user_data:
                username = user_data.get('username')
                firstname = user_data.get('firstname')
                lastname = user_data.get('lastname')
            else:
                return Response({'error_message': 'Invalid manager_id'}, status=400)

            data = {
                'manager_id': manager_id,
                'manager_username': username,
                'manager_firstname': firstname,
                'manager_lastname': lastname,
                'team_name': team_name,
                'members': [],  # Initialize members as an empty list
                'pending_requests': [],  # Initialize pending_requests as an empty list
                'captain_id': None,
                'game': game
            }

            team_ref = database.child('teams').child(game).push(data)

            # Update the user's data to set 'role' to 'manager: true'
            user_ref = database.child('users').child(manager_id)
            user_ref.update({'is_manager': True})

            return Response({'message': 'Team created successfully.'})
        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)

@api_view(['POST'])
@csrf_exempt
def join_team(request):
    if request.method == 'POST':
        team_id = request.data.get('team_id')
        localId = request.data.get('localId')

        try:
            # Verify that the localId corresponds to a valid user
            user_data = database.child('users').child(localId).get().val()
            if not user_data:
                return Response({'error_message': 'Invalid localId'}, status=400)

            # Retrieve the username, email, firstname and lastname from the user data
            username = user_data.get('username')
            email = user_data.get('email')
            firstname = user_data.get('firstname')
            lastname = user_data.get('lastname')

            # Retrieve all the game categories data from Firebase
            all_games = database.child('teams').get().val()
            
            if all_games:
                # Loop through each game category
                for game, teams in all_games.items():
                    # Check if team with the given team_id exists
                    if team_id in teams:
                        team_data = teams[team_id]
                        # Add the player's details to the pending_requests list
                        pending_requests = team_data.get('pending_requests', [])
                        pending_requests.append({'team_id': team_id, 'localId': localId, 'username': username, 'email': email, 'firstname': firstname, 'lastname': lastname})
                        
                        # Update the pending_requests field in the database
                        database.child('teams').child(game).child(team_id).update({'pending_requests': pending_requests})

                        return Response({'message': 'Request sent successfully.'})

            return Response({'error_message': 'Invalid team_id'}, status=400)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['POST'])
@csrf_exempt
def respond_to_request(request):
    if request.method == 'POST':
        game = request.data.get('game')  # This is needed to specify the game under which the team falls
        team_id = request.data.get('team_id')
        localId = request.data.get('localId')
        accept = request.data.get('accept')  # This should be a boolean
        manager_id = request.data.get('manager_id')  # This should be the id of the manager making the request

        try:
            team_data = database.child('teams').child(game).child(team_id).get().val()
            if not team_data:
                return Response({'error_message': 'Invalid team_id'}, status=400)

            # Check if the user making the request is the manager of the team
            if team_data['manager_id'] != manager_id:
                return Response({'error_message': 'Only the manager can accept or reject requests.'}, status=403)

            # Get the pending_requests list
            pending_requests = team_data.get('pending_requests', [])
            
            if accept:
                # Find the index of the request corresponding to the localId
                request_index = None
                for i, request in enumerate(pending_requests):
                    if request.get('localId') == localId:
                        request_index = i
                        break

                # Remove the player's id from the pending_requests list if it is accepted
                if request_index is not None:
                    pending_requests.pop(request_index)

                    # Update the pending_requests field with the modified list
                    database.child('teams').child(game).child(team_id).update({'pending_requests': pending_requests})

                    # Get the player's details
                    player_data = database.child('users').child(localId).get().val()
                    if not player_data:
                        return Response({'error_message': 'Invalid localId'}, status=400)

                    player_details = {
                        'username': player_data.get('username'),
                        'firstname': player_data.get('firstname'),
                        'lastname': player_data.get('lastname'),
                        'id': localId
                    }

                    # Add the player to the members list
                    members = team_data.get('members', [])
                    members.append(player_details)

                    # Update the members field
                    database.child('teams').child(game).child(team_id).update({'members': members})

                else:
                    return Response({'error_message': 'Invalid localId'}, status=400)

            return Response({'message': 'Request processed successfully.'})
        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)





@api_view(['GET'])
def get_all_teams(request):
    if request.method == 'GET':
        try:
            games_data = database.child('teams').get().val()
            if not games_data:
                return Response({'error_message': 'No teams found'}, status=404)

            teams_list = []
            for game, teams in games_data.items():
                for team_id, team in teams.items():
                    team_info = {
                        'team_id': team_id,  # This is the key of the team in the 'teams' node
                        'team_name': team.get('team_name'),
                        'manager': {
                            'username': team.get('manager_username'),
                            'firstname': team.get('manager_firstname'),
                            'lastname': team.get('manager_lastname'),
                            'id': team.get('manager_id'),
                        },
                        'members': team.get('members'),
                        'game': game
                    }
                    teams_list.append(team_info)
                    print(team_info)

            return Response({'teams': teams_list}, status=200)
        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)



# @api_view(['POST'])
# @csrf_exempt
# def join_team(request):
#     if request.method == 'POST':
#         user_id = request.data.get('user_id')
#         team_id = request.data.get('team_id')

#         try:
#             user_data = database.child('users').child(user_id).get().val()
#             if user_data:
#                 request_data = {
#                     'user_id': user_id,
#                     'username': user_data.get('username'),
#                     'firstname': user_data.get('firstname'),
#                     'lastname': user_data.get('lastname'),
#                 }
#             else:
#                 return Response({'error_message': 'Invalid user_id'}, status=400)
            
#             team_ref = database.child('teams').child(team_id)
#             current_requests = team_ref.child('pending_requests').get().val() or []

#             # Prevent duplicate requests
#             if any(req['user_id'] == user_id for req in current_requests):
#                 return Response({'error_message': 'Request already sent'}, status=400)

#             current_requests.append(request_data)
#             team_ref.update({'pending_requests': current_requests})

#             return Response({'message': 'Request to join team sent successfully.'})
#         except Exception as e:
#             return Response({'error_message': str(e)}, status=400)

#     return Response({'error_message': 'Invalid request'}, status=400)


# @api_view(['POST'])
# @csrf_exempt
# def manage_team_request(request):
#     if request.method == 'POST':
#         user_id = request.data.get('user_id')
#         team_id = request.data.get('team_id')
#         action = request.data.get('action')  # 'accept' or 'decline'

#         try:
#             team_ref = database.child('teams').child(team_id)
#             current_requests = team_ref.child('pending_requests').get().val() or []
#             current_members = team_ref.child('members').get().val() or []

#             # Find the request to be managed
#             for i, req in enumerate(current_requests):
#                 if req['user_id'] == user_id:
#                     if action == 'accept':
#                         current_members.append(req)
#                     current_requests.pop(i)
#                     break
#             else:
#                 return Response({'error_message': 'No pending request from this user'}, status=400)

#             # Update the team's members and pending_requests
#             team_ref.update({'members': current_members, 'pending_requests': current_requests})

#             return Response({'message': f'Request to join team has been {action}ed.'})
#         except Exception as e:
#             return Response({'error_message': str(e)}, status=400)

#     return Response({'error_message': 'Invalid request'}, status=400)

@api_view(['GET'])
@csrf_exempt
def get_team_info(request, manager_id):
    if request.method == 'GET':
        try:
            # Retrieve all the game categories data from Firebase
            all_games = database.child('teams').get().val()
            
            if all_games:
                # Loop through each game category
                for game, teams in all_games.items():
                    # Find the team that has the given manager_id
                    for team_id, team_info in teams.items():
                        if team_info.get('manager_id') == manager_id:
                            return Response(team_info)
                
                # If no team is found with the given manager_id
                return Response({'error_message': 'No team found for the given manager_id'}, status=400)
            
            else:
                return Response({'error_message': 'No teams found'}, status=400)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)

@api_view(['POST'])
@csrf_exempt
def create_scrim(request):
    if request.method == 'POST':
        manager_id = request.data.get('manager_id')
        team_name = request.data.get('team_name')
        game = request.data.get('game')
        date = request.data.get('date')
        time = request.data.get('time')
        preferences = request.data.get('preferences')
        contact = request.data.get('contact')

        try:
            user_data = database.child('users').child(manager_id).get().val()
            if user_data:
                username = user_data.get('username')
            else:
                return Response({'error_message': 'Invalid manager_id'}, status=400)

            data = {
                'manager_id': manager_id,
                'manager_username': username,
                'team_name': team_name,
                'game': game,
                'date': date,
                'time': time,
                'preferences': preferences,
                'contact': contact,
            }

            scrim_ref = database.child('scrims').child(game).push(data)

            return Response({'message': 'Scrim created successfully.'})
        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)

@api_view(['GET'])
@csrf_exempt
def get_scrim_details(request, game, scrim_id):
    if request.method == 'GET':
        try:
            # Retrieve the scrim details for the given game and scrim_id from Firebase
            scrim = database.child('scrims').child(game).child(scrim_id).get().val()

            if scrim:
                # Fetch the team name based on the manager_id from the scrimmage details
                manager_id = scrim.get('manager_id')
                team = database.child('teams').child(manager_id).get().val()

                return Response(scrim)
            else:
                return Response({'error_message': 'No scrim found for the given id'}, status=400)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)



@api_view(['GET'])
@csrf_exempt
def get_all_scrims(request, game):
    if request.method == 'GET':
        try:
            # Retrieve all scrims for the given game from Firebase
            scrims = database.child('scrims').child(game).get().val()

            if scrims:
                result_scrims = []
                for scrim_id, scrim_data in scrims.items():
                    manager_id = scrim_data.get('manager_id')
                    team_name = None

                    if manager_id:
                        # Fetch the team name based on the manager_id from the database
                        team_data = database.child('teams').child(manager_id).get().val()
                        if team_data:
                            team_name = team_data.get('team_name')

                    # Add the team name to the scrimmage data
                    scrim_data['team_name'] = team_name
                    result_scrims.append({scrim_id: scrim_data})

                return Response(result_scrims)
            else:
                return Response({'error_message': 'No scrims found for the given game'}, status=400)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['POST'])
@csrf_exempt
def create_organization(request):
    if request.method == 'POST':
        localId = request.data.get('localId')
        org_name = request.data.get('org_name')
        org_description = request.data.get('org_description')

        try:
            # Fetch the owner's details from the database
            owner_data = database.child('users').child(localId).get().val()
            if not owner_data:
                return Response({'error_message': 'Invalid localId'}, status=400)

            # Create the organization
            org_data = {
                'org_name': org_name,
                'owner': {
                    'username': owner_data.get('username', ''),
                    'firstname': owner_data.get('firstname', ''),
                    'lastname': owner_data.get('lastname', ''),
                    'localId': localId  # Optionally store the localId of the owner
                },
                'members': [],  # Set members to None for now
                'org_description': org_description,
                'is_approved': False  # The org needs to be approved by the admin first
            }

            # Save the organization data in the "pending_approval" section of the database
            pending_org_ref = database.child('pending_approval').push(org_data)

            # Get the unique key generated by Firebase for the newly created organization
            org_id = pending_org_ref.get('name')  # Retrieve the key using 'name' attribute

            return Response({'message': 'Organization created successfully. The organization is pending admin approval.',
                             'org_id': org_id})

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['POST'])
@csrf_exempt
def approve_organization(request):
    if request.method == 'POST':
        localId = request.data.get('localId')
        org_id = request.data.get('org_id')

        try:
            # Check if the admin user has admin privileges (isAdmin set to True)
            admin_user_data = database.child('users').child(localId).get().val()
            if admin_user_data and admin_user_data.get('isAdmin', False):
                # Fetch the pending organization data from the database
                pending_org_data = database.child('pending_approval').child(org_id).get().val()
                if not pending_org_data:
                    return Response({'error_message': 'Invalid org_id'}, status=400)

                # Move the approved organization data to the "organizations" section
                database.child('organizations').child(org_id).set(pending_org_data)

                # Set the 'is_approved' flag to True in the approved organization data
                database.child('organizations').child(org_id).update({'is_approved': True})

                # Remove the organization data from the "pending_approval" section
                database.child('pending_approval').child(org_id).remove()

                return Response({'message': 'Organization approved successfully.'})
            else:
                return Response({'error_message': 'You do not have admin privileges to approve an organization.'}, status=403)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['GET'])
@csrf_exempt
def get_all_organizations(request):
    if request.method == 'GET':
        try:
            # Fetch all organizations from the database
            organizations = database.child('organizations').get()

            # Prepare the organizations data
            organizations_data = []
            for org in organizations.each():
                org_data = org.val()
                org_data['id'] = org.key()
                organizations_data.append(org_data)

            # Return the organizations data
            return Response(organizations_data)

        except Exception as e:
            # Handle errors and return an appropriate response
            error_message = str(e)
            return Response({'error_message': error_message}, status=500)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['POST'])
@csrf_exempt
def join_organization(request):
    if request.method == 'POST':
        localId = request.data.get('localId')
        org_id = request.data.get('org_id')

        try:
            # Fetch the organization data from the database
            org_data = database.child('organizations').child(org_id).get().val()
            if not org_data:
                return Response({'error_message': 'Invalid org_id'}, status=400)

            # Check if the organization is approved by the admin
            if org_data.get('is_approved', False):
                # Fetch the user data from the database
                user_data = database.child('users').child(localId).get().val()
                if not user_data:
                    return Response({'error_message': 'Invalid localId'}, status=400)

                # Update the user data to be a member of the organization and mark them as an organizer
                if 'organizations' not in user_data:
                    user_data['organizations'] = {}

                user_data['organizations'][org_id] = {'isOrganizer': False}
                if 'is_organizer' in user_data and user_data['is_organizer']:
                    user_data['organizations'][org_id]['isOrganizer'] = True

                # Save the updated user data in the database
                database.child('users').child(localId).update(user_data)

                return Response({'message': 'You have joined the organization as a member.'})
            else:
                return Response({'error_message': 'The organization is not approved yet. Please wait for approval.'}, status=403)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)


@api_view(['POST'])
@csrf_exempt
def approve_member(request):
    if request.method == 'POST':
        owner_localId = request.data.get('owner_localId')
        org_id = request.data.get('org_id')
        member_localId = request.data.get('member_localId')

        try:
            # Fetch the organization data from the database
            org_data = database.child('organizations').child(org_id).get().val()
            if not org_data:
                return Response({'error_message': 'Invalid org_id'}, status=400)

            # Check if the user making the request is the owner of the organization
            owner_data = database.child('users').child(owner_localId).get().val()
            if not owner_data or org_data['owner']['localId'] != owner_localId:
                return Response({'error_message': 'You do not have permission to approve members.'}, status=403)

            # Check if the organization is approved by the admin
            if org_data.get('is_approved', False):
                # Fetch the member's data from the database
                member_data = database.child('users').child(member_localId).get().val()
                if not member_data:
                    return Response({'error_message': 'Invalid member_localId'}, status=400)

                # Update the user data to be a member of the organization and mark them as an organizer
                if 'organizations' not in member_data:
                    member_data['organizations'] = {}

                member_data['organizations'][org_id] = {'isOrganizer': True}
                member_data['is_organizer'] = True

                # Save the updated member data in the database
                database.child('users').child(member_localId).update(member_data)

                # Move the approved member's details to the 'members' section of the organization
                if 'members' not in org_data:
                    org_data['members'] = {}
                org_data['members'][member_localId] = {
                    'firstname': member_data.get('firstname', ''),
                    'lastname': member_data.get('lastname', ''),
                    'username': member_data.get('username', ''),
                    'isOrganizer': True,
                }

                # Remove the member's request from the organization's pending_requests section
                if 'pending_requests' in org_data and member_localId in org_data['pending_requests']:
                    del org_data['pending_requests'][member_localId]

                database.child('organizations').child(org_id).update(org_data)

                return Response({'message': 'Member approved successfully.'})
            else:
                return Response({'error_message': 'The organization is not approved yet. Please wait for approval.'}, status=403)

        except Exception as e:
            return Response({'error_message': str(e)}, status=400)

    return Response({'error_message': 'Invalid request'}, status=400)
