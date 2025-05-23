let
    sections = metadata["sidebar"]
    sections = [
        @htl("""
        $([
            let
                input = other_page.input
                output = other_page.output
                
                name = get(output.frontmatter, "title", basename(input.relative_path))
                desc = get(output.frontmatter, "description", nothing)
                tags = get(output.frontmatter, "tags", String[])
                date = get(output.frontmatter, "date", nothing)

                class = [
                    "no-decoration",
                    ("tag_$(replace(x, " "=>"_"))" for x in tags)...,
                ]
                if date !== nothing
                    @htl("""<a title=$(desc) class=$(class) href=$(root_url * "/" * other_page.url)>
                        <h3>$(name)</h3>
                        $(date)
                    </a>""")
                else
                    nothing
                end
            end for other_page in collections[section_id].pages
        ])
        """)
        for (section_id, section_name) in sections
    ]

    isempty(sections) ? nothing : @htl("""<div class="wide subjectscontainer">
    <h1>Schedule</h1>
    <div class="subjects">
      $(sections)
    </div>
    </div>
    """)
end