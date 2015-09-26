package DDGC::Feedback::Config::Feature;
# ABSTRACT:

use strict;
use warnings;

sub feedback_title { "I've got a feature request." }

sub feedback {[
  { description => "We'd love your suggestions!. Please check our <a href='https://duck.co/help'>Help pages</a> for common requests like making an email service or a browser. If you can't find what you're looking for, use the options below:", type => "info", icon => "newspaper", },

  { description => "It's a feature that could be an Instant Answer", icon => "sun" },

    "Please submit Instant Answer ideas to our community voting platform at <a href='https://duck.co/ideas'>https://duck.co/ideas</a>. If you're a developer, you can even make them yourself at <a href='http://duckduckhack.com/'>http://duckduckhack.com/</a>.",

  { description => "It's a feature that wouldn’t work as an Instant Answer", icon => "coffee" },
    "Please submit your idea to our community forum so that others can help expand (or even develop) your idea: <a href='https://duck.co/forum'>https://duck.co/forum</a>",

  { description => "It's a translation request", icon => "globe" },
    "You can translate DuckDuckGo to your language through the <a href='https://duck.co/translate'>Community Platform</a>. If you don't see your language available, please request it <a href='https://duck.co/my/requestlanguage'>here</a>.",
    "" # workaround for non submittable ending points like this here.
]}

1;
