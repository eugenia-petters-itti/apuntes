// MongoDB Social Media Dataset para Laboratorios DBA
// Versión: 1.0
// Descripción: Dataset realista para operaciones NoSQL, agregaciones y administración MongoDB
// Tamaño aproximado: 25MB de datos

// Conectar a MongoDB y usar base de datos
use social_media_lab

// Limpiar colecciones existentes
db.users.drop()
db.posts.drop()
db.comments.drop()
db.likes.drop()
db.follows.drop()
db.groups.drop()
db.events.drop()
db.messages.drop()

// Colección de usuarios
db.users.insertMany([
    {
        _id: ObjectId(),
        username: "john_doe",
        email: "john.doe@email.com",
        profile: {
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: new Date("1990-05-15"),
            gender: "male",
            location: {
                city: "New York",
                state: "NY",
                country: "USA",
                coordinates: [-74.006, 40.7128]
            },
            bio: "Software developer passionate about technology and innovation.",
            avatar: "https://example.com/avatars/john_doe.jpg",
            website: "https://johndoe.dev"
        },
        settings: {
            privacy: "public",
            notifications: {
                email: true,
                push: true,
                sms: false
            },
            theme: "dark"
        },
        stats: {
            postsCount: 0,
            followersCount: 0,
            followingCount: 0,
            likesReceived: 0
        },
        isVerified: false,
        isActive: true,
        createdAt: new Date("2023-01-15T10:30:00Z"),
        lastLoginAt: new Date("2024-01-07T15:45:00Z"),
        tags: ["developer", "tech", "javascript", "nodejs"]
    },
    {
        _id: ObjectId(),
        username: "jane_smith",
        email: "jane.smith@email.com",
        profile: {
            firstName: "Jane",
            lastName: "Smith",
            dateOfBirth: new Date("1988-09-22"),
            gender: "female",
            location: {
                city: "Los Angeles",
                state: "CA",
                country: "USA",
                coordinates: [-118.2437, 34.0522]
            },
            bio: "Digital marketing expert and content creator. Love traveling and photography.",
            avatar: "https://example.com/avatars/jane_smith.jpg",
            website: "https://janesmith.blog"
        },
        settings: {
            privacy: "friends",
            notifications: {
                email: true,
                push: true,
                sms: true
            },
            theme: "light"
        },
        stats: {
            postsCount: 0,
            followersCount: 0,
            followingCount: 0,
            likesReceived: 0
        },
        isVerified: true,
        isActive: true,
        createdAt: new Date("2023-02-20T14:20:00Z"),
        lastLoginAt: new Date("2024-01-07T18:30:00Z"),
        tags: ["marketing", "photography", "travel", "content"]
    }
])

// Función para generar usuarios adicionales
function generateUsers(count) {
    const firstNames = ["Michael", "Sarah", "David", "Lisa", "Robert", "Jennifer", "William", "Mary", "James", "Patricia", "Christopher", "Linda", "Daniel", "Barbara", "Matthew", "Elizabeth", "Anthony", "Helen", "Mark", "Nancy", "Donald", "Betty", "Steven", "Dorothy", "Paul", "Sandra", "Andrew", "Kimberly", "Joshua", "Donna", "Kenneth", "Carol", "Kevin", "Ruth", "Brian", "Sharon", "George", "Michelle", "Edward", "Laura"]
    const lastNames = ["Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green"]
    const cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose", "Austin", "Jacksonville", "Fort Worth", "Columbus", "Charlotte", "San Francisco", "Indianapolis", "Seattle", "Denver", "Washington"]
    const states = ["NY", "CA", "IL", "TX", "AZ", "PA", "TX", "CA", "TX", "CA", "TX", "FL", "TX", "OH", "NC", "CA", "IN", "WA", "CO", "DC"]
    const domains = ["gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "aol.com", "icloud.com"]
    const themes = ["light", "dark", "auto"]
    const privacySettings = ["public", "friends", "private"]
    const tags = ["tech", "travel", "food", "fitness", "music", "art", "photography", "gaming", "sports", "books", "movies", "fashion", "health", "business", "education", "science"]
    
    let users = []
    
    for (let i = 3; i <= count + 2; i++) {
        const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]
        const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]
        const username = (firstName + "_" + lastName).toLowerCase() + Math.floor(Math.random() * 1000)
        const cityIndex = Math.floor(Math.random() * cities.length)
        const domain = domains[Math.floor(Math.random() * domains.length)]
        
        const user = {
            _id: ObjectId(),
            username: username,
            email: username + "@" + domain,
            profile: {
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: new Date(1970 + Math.floor(Math.random() * 35), Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
                gender: Math.random() > 0.5 ? "male" : "female",
                location: {
                    city: cities[cityIndex],
                    state: states[cityIndex],
                    country: "USA",
                    coordinates: [-180 + Math.random() * 360, -90 + Math.random() * 180]
                },
                bio: "User bio for " + firstName + " " + lastName + ". Interested in various topics and connecting with people.",
                avatar: "https://example.com/avatars/" + username + ".jpg",
                website: Math.random() > 0.7 ? "https://" + username + ".com" : null
            },
            settings: {
                privacy: privacySettings[Math.floor(Math.random() * privacySettings.length)],
                notifications: {
                    email: Math.random() > 0.3,
                    push: Math.random() > 0.2,
                    sms: Math.random() > 0.8
                },
                theme: themes[Math.floor(Math.random() * themes.length)]
            },
            stats: {
                postsCount: 0,
                followersCount: 0,
                followingCount: 0,
                likesReceived: 0
            },
            isVerified: Math.random() > 0.95,
            isActive: Math.random() > 0.05,
            createdAt: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60)),
            lastLoginAt: new Date(2024, 0, Math.floor(Math.random() * 7) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60)),
            tags: tags.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 5) + 1)
        }
        
        users.push(user)
    }
    
    return users
}

// Insertar usuarios adicionales
const additionalUsers = generateUsers(1000)
db.users.insertMany(additionalUsers)

// Crear índices para usuarios
db.users.createIndex({ username: 1 }, { unique: true })
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ "profile.location.city": 1 })
db.users.createIndex({ "profile.location.coordinates": "2dsphere" })
db.users.createIndex({ tags: 1 })
db.users.createIndex({ createdAt: 1 })
db.users.createIndex({ lastLoginAt: 1 })
db.users.createIndex({ isActive: 1 })

// Función para generar posts
function generatePosts(userIds, count) {
    const postTypes = ["text", "image", "video", "link", "poll"]
    const hashtags = ["#tech", "#travel", "#food", "#fitness", "#music", "#art", "#photography", "#gaming", "#sports", "#books", "#movies", "#fashion", "#health", "#business", "#education", "#science", "#nature", "#lifestyle", "#motivation", "#inspiration"]
    const sampleTexts = [
        "Just had an amazing day exploring the city! The weather was perfect and I discovered some great new places.",
        "Working on an exciting new project. Can't wait to share more details soon!",
        "Beautiful sunset today. Sometimes you just need to stop and appreciate the simple things in life.",
        "Great workout session this morning. Feeling energized and ready to tackle the day!",
        "Trying out a new recipe tonight. Cooking has become such a relaxing hobby for me.",
        "Finished reading an incredible book. Highly recommend it to anyone interested in personal development.",
        "Weekend vibes! Planning to spend some quality time with family and friends.",
        "Just launched my new website. It's been months of hard work but totally worth it!",
        "Coffee and coding - the perfect combination for a productive morning.",
        "Grateful for all the amazing people in my life. Feeling blessed today!"
    ]
    
    let posts = []
    
    for (let i = 0; i < count; i++) {
        const userId = userIds[Math.floor(Math.random() * userIds.length)]
        const postType = postTypes[Math.floor(Math.random() * postTypes.length)]
        const selectedHashtags = hashtags.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 4))
        
        const post = {
            _id: ObjectId(),
            authorId: userId,
            type: postType,
            content: {
                text: sampleTexts[Math.floor(Math.random() * sampleTexts.length)] + " " + selectedHashtags.join(" "),
                media: postType !== "text" ? {
                    url: `https://example.com/media/${postType}/${i}.${postType === "image" ? "jpg" : postType === "video" ? "mp4" : "html"}`,
                    thumbnail: postType === "video" ? `https://example.com/thumbnails/${i}.jpg` : null,
                    duration: postType === "video" ? Math.floor(Math.random() * 300) + 30 : null
                } : null,
                poll: postType === "poll" ? {
                    question: "What's your favorite programming language?",
                    options: [
                        { text: "JavaScript", votes: Math.floor(Math.random() * 100) },
                        { text: "Python", votes: Math.floor(Math.random() * 100) },
                        { text: "Java", votes: Math.floor(Math.random() * 100) },
                        { text: "Other", votes: Math.floor(Math.random() * 50) }
                    ],
                    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
                } : null
            },
            hashtags: selectedHashtags,
            mentions: Math.random() > 0.8 ? [userIds[Math.floor(Math.random() * userIds.length)]] : [],
            location: Math.random() > 0.7 ? {
                name: "Sample Location",
                coordinates: [-180 + Math.random() * 360, -90 + Math.random() * 180]
            } : null,
            visibility: Math.random() > 0.1 ? "public" : Math.random() > 0.5 ? "friends" : "private",
            stats: {
                likesCount: Math.floor(Math.random() * 500),
                commentsCount: Math.floor(Math.random() * 100),
                sharesCount: Math.floor(Math.random() * 50),
                viewsCount: Math.floor(Math.random() * 1000) + 100
            },
            isEdited: Math.random() > 0.9,
            isPinned: Math.random() > 0.95,
            createdAt: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60)),
            updatedAt: new Date(2024, 0, Math.floor(Math.random() * 7) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60))
        }
        
        posts.push(post)
    }
    
    return posts
}

// Obtener IDs de usuarios para generar posts
const userIds = db.users.find({}, { _id: 1 }).toArray().map(user => user._id)

// Generar y insertar posts
const posts = generatePosts(userIds, 5000)
db.posts.insertMany(posts)

// Crear índices para posts
db.posts.createIndex({ authorId: 1 })
db.posts.createIndex({ type: 1 })
db.posts.createIndex({ hashtags: 1 })
db.posts.createIndex({ mentions: 1 })
db.posts.createIndex({ visibility: 1 })
db.posts.createIndex({ createdAt: -1 })
db.posts.createIndex({ "stats.likesCount": -1 })
db.posts.createIndex({ "location.coordinates": "2dsphere" })

// Función para generar comentarios
function generateComments(userIds, postIds, count) {
    const sampleComments = [
        "Great post! Thanks for sharing.",
        "I totally agree with this perspective.",
        "This is really interesting, never thought about it that way.",
        "Love this! Keep up the great work.",
        "Thanks for the inspiration!",
        "This made my day, thank you!",
        "Couldn't agree more with this.",
        "Awesome content as always!",
        "This is exactly what I needed to hear today.",
        "Such a thoughtful post, really appreciate it."
    ]
    
    let comments = []
    
    for (let i = 0; i < count; i++) {
        const comment = {
            _id: ObjectId(),
            postId: postIds[Math.floor(Math.random() * postIds.length)],
            authorId: userIds[Math.floor(Math.random() * userIds.length)],
            content: {
                text: sampleComments[Math.floor(Math.random() * sampleComments.length)],
                media: Math.random() > 0.9 ? {
                    url: `https://example.com/comment-media/${i}.jpg`,
                    type: "image"
                } : null
            },
            parentCommentId: Math.random() > 0.8 ? comments.length > 0 ? comments[Math.floor(Math.random() * Math.min(comments.length, 100))]._id : null : null,
            mentions: Math.random() > 0.9 ? [userIds[Math.floor(Math.random() * userIds.length)]] : [],
            stats: {
                likesCount: Math.floor(Math.random() * 50),
                repliesCount: Math.floor(Math.random() * 10)
            },
            isEdited: Math.random() > 0.95,
            createdAt: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60)),
            updatedAt: new Date(2024, 0, Math.floor(Math.random() * 7) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60))
        }
        
        comments.push(comment)
    }
    
    return comments
}

// Obtener IDs de posts para generar comentarios
const postIds = db.posts.find({}, { _id: 1 }).toArray().map(post => post._id)

// Generar y insertar comentarios
const comments = generateComments(userIds, postIds, 15000)
db.comments.insertMany(comments)

// Crear índices para comentarios
db.comments.createIndex({ postId: 1 })
db.comments.createIndex({ authorId: 1 })
db.comments.createIndex({ parentCommentId: 1 })
db.comments.createIndex({ createdAt: -1 })

// Función para generar likes
function generateLikes(userIds, postIds, commentIds, count) {
    let likes = []
    let usedCombinations = new Set()
    
    for (let i = 0; i < count; i++) {
        const userId = userIds[Math.floor(Math.random() * userIds.length)]
        const isPostLike = Math.random() > 0.3
        const targetId = isPostLike ? 
            postIds[Math.floor(Math.random() * postIds.length)] : 
            commentIds[Math.floor(Math.random() * commentIds.length)]
        
        const combination = `${userId}_${targetId}_${isPostLike ? 'post' : 'comment'}`
        
        if (!usedCombinations.has(combination)) {
            usedCombinations.add(combination)
            
            const like = {
                _id: ObjectId(),
                userId: userId,
                targetId: targetId,
                targetType: isPostLike ? "post" : "comment",
                createdAt: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60))
            }
            
            likes.push(like)
        }
    }
    
    return likes
}

// Obtener IDs de comentarios para generar likes
const commentIds = db.comments.find({}, { _id: 1 }).toArray().map(comment => comment._id)

// Generar y insertar likes
const likes = generateLikes(userIds, postIds, commentIds, 25000)
db.likes.insertMany(likes)

// Crear índices para likes
db.likes.createIndex({ userId: 1 })
db.likes.createIndex({ targetId: 1 })
db.likes.createIndex({ targetType: 1 })
db.likes.createIndex({ userId: 1, targetId: 1, targetType: 1 }, { unique: true })
db.likes.createIndex({ createdAt: -1 })

// Función para generar relaciones de seguimiento
function generateFollows(userIds, count) {
    let follows = []
    let usedCombinations = new Set()
    
    for (let i = 0; i < count; i++) {
        const followerId = userIds[Math.floor(Math.random() * userIds.length)]
        const followingId = userIds[Math.floor(Math.random() * userIds.length)]
        
        if (followerId.toString() !== followingId.toString()) {
            const combination = `${followerId}_${followingId}`
            
            if (!usedCombinations.has(combination)) {
                usedCombinations.add(combination)
                
                const follow = {
                    _id: ObjectId(),
                    followerId: followerId,
                    followingId: followingId,
                    status: Math.random() > 0.05 ? "active" : "pending",
                    createdAt: new Date(2023, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1, Math.floor(Math.random() * 24), Math.floor(Math.random() * 60))
                }
                
                follows.push(follow)
            }
        }
    }
    
    return follows
}

// Generar y insertar relaciones de seguimiento
const follows = generateFollows(userIds, 8000)
db.follows.insertMany(follows)

// Crear índices para follows
db.follows.createIndex({ followerId: 1 })
db.follows.createIndex({ followingId: 1 })
db.follows.createIndex({ followerId: 1, followingId: 1 }, { unique: true })
db.follows.createIndex({ status: 1 })
db.follows.createIndex({ createdAt: -1 })

// Crear colección de grupos
db.groups.insertMany([
    {
        _id: ObjectId(),
        name: "JavaScript Developers",
        description: "A community for JavaScript developers to share knowledge and collaborate.",
        category: "Technology",
        privacy: "public",
        adminIds: [userIds[0]],
        moderatorIds: [userIds[1], userIds[2]],
        memberIds: userIds.slice(0, 100),
        stats: {
            memberCount: 100,
            postCount: 0,
            activeMembers: 85
        },
        settings: {
            allowMemberPosts: true,
            requireApproval: false,
            allowInvites: true
        },
        tags: ["javascript", "programming", "web-development"],
        avatar: "https://example.com/groups/js-developers.jpg",
        cover: "https://example.com/groups/js-developers-cover.jpg",
        createdAt: new Date("2023-03-01T10:00:00Z"),
        updatedAt: new Date("2024-01-05T14:30:00Z")
    },
    {
        _id: ObjectId(),
        name: "Photography Enthusiasts",
        description: "Share your best shots and learn from fellow photographers.",
        category: "Arts & Photography",
        privacy: "public",
        adminIds: [userIds[3]],
        moderatorIds: [userIds[4]],
        memberIds: userIds.slice(50, 200),
        stats: {
            memberCount: 150,
            postCount: 0,
            activeMembers: 120
        },
        settings: {
            allowMemberPosts: true,
            requireApproval: true,
            allowInvites: true
        },
        tags: ["photography", "art", "creative"],
        avatar: "https://example.com/groups/photography.jpg",
        cover: "https://example.com/groups/photography-cover.jpg",
        createdAt: new Date("2023-04-15T16:20:00Z"),
        updatedAt: new Date("2024-01-06T09:15:00Z")
    }
])

// Crear índices para grupos
db.groups.createIndex({ name: 1 })
db.groups.createIndex({ category: 1 })
db.groups.createIndex({ privacy: 1 })
db.groups.createIndex({ adminIds: 1 })
db.groups.createIndex({ memberIds: 1 })
db.groups.createIndex({ tags: 1 })
db.groups.createIndex({ createdAt: -1 })

// Actualizar estadísticas de usuarios
db.users.aggregate([
    {
        $lookup: {
            from: "posts",
            localField: "_id",
            foreignField: "authorId",
            as: "userPosts"
        }
    },
    {
        $lookup: {
            from: "follows",
            localField: "_id",
            foreignField: "followingId",
            as: "followers"
        }
    },
    {
        $lookup: {
            from: "follows",
            localField: "_id",
            foreignField: "followerId",
            as: "following"
        }
    },
    {
        $lookup: {
            from: "likes",
            let: { userId: "$_id" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$targetType", "post"] },
                                {
                                    $in: ["$targetId", {
                                        $map: {
                                            input: "$$ROOT.userPosts",
                                            as: "post",
                                            in: "$$post._id"
                                        }
                                    }]
                                }
                            ]
                        }
                    }
                }
            ],
            as: "likesReceived"
        }
    },
    {
        $merge: {
            into: "users",
            whenMatched: [
                {
                    $set: {
                        "stats.postsCount": { $size: "$userPosts" },
                        "stats.followersCount": { $size: "$followers" },
                        "stats.followingCount": { $size: "$following" },
                        "stats.likesReceived": { $size: "$likesReceived" }
                    }
                }
            ]
        }
    }
])

// Crear vistas útiles
db.createView("activeUsers", "users", [
    {
        $match: {
            isActive: true,
            lastLoginAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
        }
    },
    {
        $project: {
            username: 1,
            "profile.firstName": 1,
            "profile.lastName": 1,
            "profile.location.city": 1,
            "stats": 1,
            lastLoginAt: 1
        }
    }
])

db.createView("popularPosts", "posts", [
    {
        $match: {
            visibility: "public",
            createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        }
    },
    {
        $sort: { "stats.likesCount": -1, "stats.commentsCount": -1 }
    },
    {
        $limit: 100
    },
    {
        $lookup: {
            from: "users",
            localField: "authorId",
            foreignField: "_id",
            as: "author"
        }
    },
    {
        $unwind: "$author"
    },
    {
        $project: {
            "content.text": 1,
            hashtags: 1,
            stats: 1,
            createdAt: 1,
            "author.username": 1,
            "author.profile.firstName": 1,
            "author.profile.lastName": 1
        }
    }
])

// Mostrar estadísticas del dataset
print("=== MONGODB SOCIAL MEDIA DATASET STATISTICS ===")
print("Users: " + db.users.countDocuments())
print("Posts: " + db.posts.countDocuments())
print("Comments: " + db.comments.countDocuments())
print("Likes: " + db.likes.countDocuments())
print("Follows: " + db.follows.countDocuments())
print("Groups: " + db.groups.countDocuments())

print("\n=== COLLECTION SIZES ===")
db.runCommand("collStats", "users").then(stats => print("Users collection size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB"))
db.runCommand("collStats", "posts").then(stats => print("Posts collection size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB"))
db.runCommand("collStats", "comments").then(stats => print("Comments collection size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB"))
db.runCommand("collStats", "likes").then(stats => print("Likes collection size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB"))
db.runCommand("collStats", "follows").then(stats => print("Follows collection size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB"))

print("\n=== SAMPLE QUERIES FOR TESTING ===")
print("1. Find users by location:")
print("db.users.find({'profile.location.city': 'New York'})")

print("\n2. Find posts with specific hashtags:")
print("db.posts.find({hashtags: '#tech'})")

print("\n3. Get user's followers count:")
print("db.follows.countDocuments({followingId: ObjectId('USER_ID')})")

print("\n4. Find most liked posts:")
print("db.posts.find().sort({'stats.likesCount': -1}).limit(10)")

print("\n5. Aggregate posts by user:")
print("db.posts.aggregate([{$group: {_id: '$authorId', postCount: {$sum: 1}}}, {$sort: {postCount: -1}}])")

print("\nDataset creation completed successfully!")
