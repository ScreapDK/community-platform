package DDGC::Web::App::Blog;

# ABSTRACT: Rendering service application for blog posts and RSS

use DDGC::Base::Web::App;
use Dancer2::Plugin::Feed;
use Scalar::Util qw/ looks_like_number /;

sub title { 'DuckDuckGo Blog' };

sub feed {
    my ( $posts ) = @_;
    create_feed(
        format  => 'Atom',
        title   => title,
        entries => [
            map {{
                id          => $_->{id},
                link        => uri_for($_->{path}),
                title       => $_->{title},
                modified    => $_->{updated},
                content     => $_->{content},
            }} @{ $posts }
        ],
    );
}

# This intercepts all routes to set a body class.
# TODO: Get a better way to do this.
get qr/^.*/ => sub {
    var( page_class => 'page-blog texture' );
    pass;
};

get '/' => sub {
    my $page = param_hmv('page') || 1;
    my $res = ddgcr_get( [ 'Blog' ], {
            page => $page,
            ( param_hmv('topic') )
                ? ( topic => param_hmv('topic') )
                : (),
        });

    if ( $res->is_success ) {
        return template 'blog/index', {
            %{$res->{ddgcr}},
            title => title,
            topic => param_hmv('topic'),
        };
    }
    else {
        status 404;
    }
};

get '/page/:page' => sub {
    forward '/', { params('route') };
};

get '/rss' => sub {
    my $p = ddgcr_get( [ 'Blog' ], { page => 1 } );
    if ( $p->is_success ) {
        return feed( $p->{ddgcr}->{posts} );
    }
    status 404;
};

get '/topic/:topic/rss' => sub {
    my $p = ddgcr_get( [ 'Blog' ], {
        page  => 1,
        topic => params('route')->{topic},
    } );
    if ( $p->is_success ) {
        return feed( $p->{ddgcr}->{posts} );
    }
    status 404;
};

get '/topic/:topic' => sub {
    forward '/', {
        topic => params('route')->{topic},
        page  => param_hmv('page') || 1,
        url   => ''
    };
};

get '/post/:id/:uri' => sub {
    my $params = params('route');
    my $post;
    # Since we have a login prompt on this page, set last_url
    # TODO: Make this happen for everything (in login handler?)
    session last_url => request->env->{REQUEST_URI};
    my $res = ddgcr_get [ 'Blog', 'post' ], { id => $params->{id} };
    if ( $res->is_success ) {
        $post = $res->{ddgcr}->{post};

        if ( $post->{uri} ne $params->{uri} ) {
            redirect '/post/' . $post->{id} . '/' . $post->{uri};
        }

        template 'blog/index', {
            %{$res->{ddgcr}},
            title => join ' : ', ( title, $post->{title} ),
        };
    }
    else {
        status 404;
    }
};

get '/:uri_or_id' => sub {
    my $uri_or_id = params('route')->{uri_or_id};
    my $req = ( looks_like_number( $uri_or_id ) )
        ? ddgcr_get [ 'Blog', 'post' ], { id => int( $uri_or_id + 0 ) }
        : ddgcr_get [ 'Blog', 'post', 'by_url' ], { url => $uri_or_id };
    if ( $req->is_success ) {

        my ($id, $uri) = (
            $req->{ddgcr}->{post}->{id},
            $req->{ddgcr}->{post}->{uri},
        );

        redirect "/post/$id/$uri";
    };
    status 404;
};

1;
