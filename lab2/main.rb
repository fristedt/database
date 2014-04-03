require 'pg'
def conn 
  PG::Connection.new("nestor2.csc.kth.se", 5432, nil, nil, "hamfri", "hamfri", "ukDobkel")
end

def init(conn)
  conn.exec("CREATE TABLE FoodStuffs (
              name TEXT,
              amount INT,
              unit TEXT,
              PRIMARY KEY (name))
            ")
  conn.exec("CREATE TABLE Recepies (
              name TEXT,
              type TEXT,
              description TEXT,
              PRIMARY KEY (name))
            ")
  conn.exec("CREATE TABLE UsedIn (
              ingredient TEXT,
              recepie TEXT,
              amount INT,
              PRIMARY KEY (ingredient, recepie),
              FOREIGN KEY (ingredient) REFERENCES FoodStuffs,
              FOREIGN KEY (recepie) REFERENCES Recepies)
            ")
  populate(conn)
end

def destroy(conn)
  conn.exec("DROP TABLE FoodStuffs, Recepies, UsedIn")
end

def populate(conn)
  conn.exec("INSERT INTO FoodStuffs VALUES 
            (
              'long grain rice',
              400,
              'g'
            ), (
              'tomato',
              2,
              'pc'
            ), (
              'onion',
              3,
              'pc'
            ), (
              'garlic',
              7,
              'cloves'
            ), (
              'red chili pepper',
              3,
              'pc'
            ), (
              'broccoli',
              700,
              'g'
            ), (
              'olive oil',
              400,
              'ml'
            ), (
              'basil',
              50,
              'g'
            ), (
              'sesame oil',
              null,
              'ml'
            ), (
              'brown sugar',
              null,
              'g'
            ), (
              'soy sauce',
              null,
              'ml')
            ")

  conn.exec("INSERT INTO Recepies VALUES
            (
              'Mexican Fried Rice',
              'Fried rice',
              'Mexican fried rice, the classic mexican fried rice dish.'
            ), (
              'Mushroom Quesadillas',
              'Tortilla dish',
              'Tasty tortilla dish.'
            ), (
              'Broccoli Stir Fry',
              'Fried rice',
              'Awesome stirt fry.')
            ")
end

