CREATE OR REPLACE FUNCTION addIngredient(ingredient TEXT, recepie TEXT, amount int)
RETURNS VOID AS $$
BEGIN
  IF EXISTS (SELECT name FROM FoodStuffs WHERE name = ingredient) THEN 
    INSERT INTO UsedIn VALUES (ingredient, recepie, amount);
    RETURN;
  END IF;
  INSERT INTO FoodStuffs VALUES (ingredient, 0);
  INSERT INTO UsedIn VALUES (ingredient, recepie, amount);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION addFood(_name TEXT, _amount int)
RETURNS VOID AS $$
BEGIN
  IF EXISTS (SELECT name FROM FoodStuffs WHERE name = _name) THEN
    UPDATE FoodStuffs SET amount = amount + _amount WHERE name = _name;
    RETURN;
  END IF;
  INSERT INTO FoodStuffs VALUES (_name, _amount);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION deleteFood(_name TEXT, _amount int)
RETURNS VOID AS $$
BEGIN
  IF EXISTS (SELECT name FROM FoodStuffs WHERE name = _name AND amount - _amount >= 0) THEN
    UPDATE FoodStuffs SET amount = amount - _amount WHERE name = _name;
    RETURN;
  END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION isCookable(_recepie TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT count(ingredient) FROM UsedIn WHERE recepie = _recepie GROUP BY recepie 
      HAVING count(ingredient) = (
        SELECT count(ingredient) 
        FROM UsedIn 
        INNER JOIN FoodStuffs 
        ON ingredient = name 
        WHERE FoodStuffs.amount - UsedIn.amount >= 0 
        AND recepie = _recepie
      )
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cookable()
RETURNS SETOF name AS $$
DECLARE 
  row RECORD;
BEGIN
  FOR row IN SELECT * FROM Recepies LOOP
    IF isCookable(row.name) THEN 
      RETURN NEXT row.name;
    END IF;
  END LOOP;
  RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION isPossiblyCookable(_recepie TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT count(ingredient) FROM UsedIn WHERE recepie = _recepie GROUP BY recepie 
      HAVING count(ingredient) = (
        SELECT count(ingredient) 
        FROM UsedIn 
        INNER JOIN FoodStuffs 
        ON ingredient = name 
        WHERE (FoodStuffs.amount - UsedIn.amount >= 0 OR FoodStuffs.amount IS NULL)
        AND recepie = _recepie
      )
    );
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION possiblyCookable()
RETURNS SETOF name AS $$
DECLARE
  row RECORD;
BEGIN
  FOR row IN SELECT * FROM Recepies LOOP
    IF isPossiblyCookable(row.name) THEN
      RETURN NEXT row.name;
    END IF;
  END LOOP;
  RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION listConditions(_recepie TEXT)
RETURNS TABLE (_ingredient TEXT, _amount INT) AS $$
BEGIN
  IF isPossiblyCookable(_recepie) THEN
    RAISE INFO 'Some amounts are unknown. Ensure that you have the following.';
    RETURN QUERY
      SELECT name, UsedIn.amount
      FROM UsedIn
      INNER JOIN FoodStuffs
      ON name = ingredient
      WHERE recepie = _recepie AND FoodStuffs.amount IS NULL;
  END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION shoppingList(_recepie TEXT)
RETURNS TABLE (_ingredient TEXT, _amount INT) AS $$
  BEGIN
    RETURN QUERY
    SELECT name, abs(FoodStuffs.amount - UsedIn.amount)
    FROM FoodStuffs
    INNER JOIN UsedIn ON name = ingredient
    WHERE recepie = _recepie AND FoodStuffs.amount - UsedIn.amount < 0;
  END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cook(_recepie TEXT) 
RETURNS VOID AS $$
DECLARE 
  row RECORD;
BEGIN
  IF isPossiblyCookable(_recepie) THEN
    FOR row IN SELECT * FROM UsedIn WHERE recepie = _recepie LOOP
      PERFORM deleteFood(row.ingredient, row.amount);
    END LOOP;
    RETURN;
  END IF;
  RAISE NOTICE 'You lack the proper ingredients!';
END;
$$
LANGUAGE plpgsql;

