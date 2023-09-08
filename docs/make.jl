using VPL
using Documenter

DocMeta.setdocmeta!(VPL, :DocTestSetup, :(using VPL); recursive=true)

makedocs(;
    modules=[VPL],
    authors="Alejandro Morales Sierra <alejandro.moralessierra@wur.nl> and contributors",
    repo="https://github.com/AleMorales/VPL.jl/blob/{commit}{path}#{line}",
    sitename="VPL.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
