enum UserQueries {
    static let me = """
    query {
        me {
            id displayName photoURL bio interests
            traits { name tier }
            badges { id name description awardedAt }
            eventsOrganized eventsAttended memberSince gender dateOfBirth noShowCount
        }
    }
    """

    static let user = """
    query User($id: ID!) {
        user(id: $id) {
            id displayName photoURL bio interests
            traits { name tier }
            badges { id name description awardedAt }
            eventsOrganized eventsAttended memberSince
        }
    }
    """

    struct MeResponse: Decodable { let me: User }
    struct UserResponse: Decodable { let user: User? }
    struct UserVariables: Encodable { let id: String }
}

enum UserMutations {
    static let createProfile = """
    mutation CreateProfile($input: CreateProfileInput!) {
        createProfile(input: $input) { id displayName photoURL bio interests }
    }
    """
    struct CreateProfileVariables: Encodable { let input: CreateProfileInput }
    struct CreateProfileInput: Encodable { let displayName: String }
    struct CreateProfileResponse: Decodable { let createProfile: User }
}
