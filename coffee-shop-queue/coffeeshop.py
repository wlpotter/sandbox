import random


class CustomerTicket:
    def __init__(self, current_time):
        self.customer_ticket_id = random.randint(100, 999)
        self.time_ordered = current_time
        self.num_drinks_ordered = random.randint(0, 4)
        self.num_food_ordered = random.randint(0, 4)
        while(self.num_drinks_ordered == 0 and self.num_food_ordered == 0):
            self.num_drinks_ordered = random.randint(0, 4)
            self.num_food_ordered = random.randint(0, 4)
        self.num_drinks_left = self.num_drinks_ordered
        self.num_food_left = self.num_food_ordered

        # defaults
        self.time_order_completed = -1

    def mark_order_completed(self, current_time):
        self.time_order_completed = current_time


"""
Problem 1: Determine the average wait-time of customers at a coffee given the
following assumptions:

1. average customers per hour =
2. average customer order is
3. average espresso drink prep time =
4. average food prep time =
5. average smoothie prep time =
6. non-espresso drinks, like drip coffee, add negligible time to a customer's
ticket

Problem 2: Determine total net income for the coffee shop based on an average
hour of operation. In addition to the above assumptions, the following can be
assumed:

1. average food retail price =
2. average food materials cost =
3. average drink retail price =
4. average drink materials cost =
5. average number of employees per shift =
6. worker hourly rate =

Problem 3: Determine whether adding an extra barista would be worth the added
labor cost and, if so, how much higher would the profit margin be?

Problem 4: Determine whether adding an extra cook would be worth the added
labor cost. Would it result in a higher profit margin than the barista?
"""
"""
Notes on objects:

Customer Ticket
- id
- time ordered
- time completed
- drinksComplete
- foodComplete
- food items
- espresso drink items
- total cost?

Order Queue


----
order queue is queue of customer ids
As drinks or food are finished, lookup the id in the customer queue and
subtract 1 from their 'left to process' variables. Once those are at 0,
the customer is done and the time completed can be recorded
After the hour simulation, loop through the customer list (=list of dictionaries?)
and find the average of the differences between the times
"""

"""
Process:

initialize the simulation

run the simulation as a sequence of 3600 seconds
events that could happen in a given second:

1. new customer order
    - randomly assign number of drinks and add that many to drink queue
    - randomly assign number of food items and add that many to food queue
    - record time begun as current time
    - add customer to customer queue
2. drink complete
    - subtract that drink from customer with matching id
    - check their drink and food left and mark complete if true
3. food complete
    - subtract that food from customer with matching id
    - check their drink and food left and mark complete if true
4. customer(s) order complete
    - note; only checked if a food or drink item is completed because otherwise
    it couldn't have been complete
    - record time complete as current time
    - move to 'completed_queue'

do any final data analysis that is requested
"""
