namespace BlogBot

open System.Net.Http
open System.Xml.Linq
open BlogBot.Domain
open BlogBot.Pipeline
open FsToolkit.ErrorHandling

module Input =

    let private httpClient = new HttpClient()

    let private parsePost (item: XElement) =
        let value name =
            item.Element(XName.Get name)
            |> Option.ofObj
            |> Option.map _.Value.Trim()
            |> Option.defaultValue ""

        { Title = value "title"
          Link = value "link"
          Description = value "description" }

    let private parseFeed (xml: string) =
        let doc = XDocument.Parse(xml)

        doc.Descendants(XName.Get "item") |> Seq.map parsePost |> Seq.toList

    let rss (feedUrl: string) : Input =
        fun () ->
            asyncResult {
                let! response =
                    async {
                        try
                            let! result = httpClient.GetStringAsync(feedUrl) |> Async.AwaitTask
                            return Ok result
                        with ex ->
                            return Error(InputError $"Failed to fetch RSS feed: {ex.Message}")
                    }

                let posts = parseFeed response

                match posts with
                | [] -> return! Error(InputError "No posts found in RSS feed")
                | posts -> return posts
            }
