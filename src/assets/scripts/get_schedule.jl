import Dates

let
    today = Dates.today()

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
                date_str = get(output.frontmatter, "date", nothing)

                if date_str !== nothing
                    upcoming = try
                        Dates.Date(string(date_str)) > today
                    catch
                        false
                    end

                    class = [
                        "no-decoration",
                        upcoming ? "upcoming-entry" : nothing,
                        ("tag_$(replace(x, " "=>"_"))" for x in tags)...,
                    ]

                    @htl("""<a title=$(desc) class=$(class) href=$(root_url * "/" * other_page.url)>
                        <h3>$(name)</h3>
                        <span class="schedule-date $(upcoming ? "upcoming-badge" : "")">$(date_str)</span>
                        $(upcoming ? @htl("""<span class="upcoming-label">Upcoming</span>""") : nothing)
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
