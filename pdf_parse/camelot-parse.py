import camelot

tables = camelot.read_pdf("retn06.pdf", pages="7-18")
if len(tables) == 0:
    print("no tables!")
    exit(1)

print(f"found {len(tables)} tables")

for i, t in enumerate(tables):
    print("----")
    print(t.parsing_report)
    print(t.df)
    t.to_csv(f"table_{i}.csv")

