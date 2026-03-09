namespace BlogBot

module Domain =

    type Post =
        { Title: string
          Link: string
          Description: string }

    type SocialPost = { Body: string; Link: string }

    /// A published post is identified by its link URL
    type PublishedPost = PublishedPost of string
