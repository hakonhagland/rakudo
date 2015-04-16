my class Failure {
    has $.exception;
    has $.backtrace;
    has $!handled;

    method new($exception) {
         self.bless(:$exception);
    }

    submethod BUILD (:$!exception) {
        $!backtrace = $!exception.backtrace() || Backtrace.new(9);
    }

    # TODO: should be Failure:D: multi just like method Bool,
    # but obscure problems prevent us from making Mu.defined
    # a multi. See http://irclog.perlgeek.de/perl6/2011-06-28#i_4016747
    method defined() {
        $!handled =1 if nqp::isconcrete(self);
        Bool::False;
    }
    multi method Bool(Failure:D:) { $!handled = 1; Bool::False; }

    method Int(Failure:D:)        { $!handled ?? 0   !! $!exception.throw($!backtrace); }
    method Num(Failure:D:)        { $!handled ?? 0e0 !! $!exception.throw($!backtrace); }
    method Numeric(Failure:D:)    { $!handled ?? 0e0 !! $!exception.throw($!backtrace); }
    multi method Str(Failure:D:)  { $!handled ?? ''  !! $!exception.throw($!backtrace); }
    multi method gist(Failure:D:) { $!handled ?? $.mess !! $!exception.throw($!backtrace); }
    method mess (Failure:D:) {
        self.exception.message ~ "\n" ~ self.backtrace;
    }

    Failure.^add_fallback(
        -> $, $ { True },
        method ($name) {
            $!exception.throw;
        }
    );
    method sink() is hidden-from-backtrace {
        $!exception.throw($!backtrace) unless $!handled
    }
}

proto sub fail(|) is hidden-from-backtrace {*};
multi sub fail(Exception $e) is hidden-from-backtrace {
    my $fail := Failure.new($e);
    my Mu $return := nqp::getlexcaller('RETURN');
    $return($fail) unless nqp::isnull($return);
    $fail
}
multi sub fail($payload) is hidden-from-backtrace {
    my $fail := Failure.new(X::AdHoc.new(:$payload));
    my Mu $return := nqp::getlexcaller('RETURN');
    $return($fail) unless nqp::isnull($return);
    $fail
}
multi sub fail(*@msg) is hidden-from-backtrace {
    my $payload = @msg == 1 ?? @msg[0] !! @msg.join;
    my $fail := Failure.new(X::AdHoc.new(:$payload));
    my Mu $return := nqp::getlexcaller('RETURN');
    $return($fail) unless nqp::isnull($return);
    $fail
}

multi sub die(Failure:D $failure) is hidden-from-backtrace {
    $failure.exception.throw
}
multi sub die(Failure:U) is hidden-from-backtrace {
    X::AdHoc('Failure').throw
}

# vim: ft=perl6 expandtab sw=4
