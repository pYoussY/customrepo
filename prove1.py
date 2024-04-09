

import pulp

# Define the problem
prob = pulp.LpProblem("Transportation Problem", pulp.LpMinimize)

# Define decision variables
# Variables represent the amount of goods transported from each factory to each warehouse
# We use a nested dictionary to store the variables
# Example: x[factory][warehouse] represents the amount transported from factory to warehouse
factories = ['Factory1', 'Factory2']
warehouses = ['WarehouseA', 'WarehouseB', 'WarehouseC']

x = pulp.LpVariable.dicts("shipment", ((f, w) for f in factories for w in warehouses), lowBound=0, cat='Continuous')

# Define objective function
# We aim to minimize the total transportation cost
prob += 10*x[('Factory1', 'WarehouseA')] + 12*x[('Factory1', 'WarehouseB')] + 15*x[('Factory1', 'WarehouseC')] \
      + 9*x[('Factory2', 'WarehouseA')] + 11*x[('Factory2', 'WarehouseB')] + 13*x[('Factory2', 'WarehouseC')]
# Define supply constraints for each factory
prob += x[('Factory1')][('WarehouseA')] + x[('Factory1')][('WarehouseB')] + x[('Factory1')][('WarehouseC')] <= 20
prob += x[('Factory2')][('WarehouseA')] + x[('Factory2')][('WarehouseB')] + x[('Factory2')][('WarehouseC')] <= 30

# Define demand constraints for each warehouse
prob += x[('Factory1')][('WarehouseA')] + x[('Factory2')][('WarehouseA')] >= 10
prob += x[('Factory1')][('WarehouseB')] + x[('Factory2')][('WarehouseB')] >= 20
prob += x[('Factory1')][('WarehouseC')] + x[('Factory2')][('WarehouseC')] >= 30

# Solve the problem
prob.solve()

# Print the optimal solution
print("Optimal Solution:")
for f in factories:
    for w in warehouses:
        print(f"Amount from {f} to {w}: {x[f][w].varValue}")

print("Total Cost:", pulp.value(prob.objective))

