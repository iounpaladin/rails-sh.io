App.messages = App.cable.subscriptions.create('MessagesChannel', {
    received: function (data) {
        if (data.custom === 'ignore') {
            return;
        }

        if (data.custom === 'fasenact') {
            count = /\((\d+)\/\d+\)/.exec(data.message)[1];
            $(".enactedpolicies-container").append("<div class=\"enactedpolicies-card-container flippedY inplace fascist0\">\n" +
                "        <div class=\"enactedpolicies-card front\"></div>\n" +
                "        <div class=\"enactedpolicies-card back fascist\"></div>\n" +
                "      </div>");

            setTimeout(function () {
                x = $(".fascist0");
                x[0].classList.remove("fascist0");
                x[0].classList.add("fascist" + count);
            }, 100);
        } else if (data.custom === 'libenact') {
            count = /\((\d+)\/\d+\)/.exec(data.message)[1];
            $(".enactedpolicies-container").append("<div class=\"enactedpolicies-card-container flippedY inplace liberal0\">\n        <div class=\"enactedpolicies-card front\"></div>\n        <div class=\"enactedpolicies-card back liberal\"></div>\n      </div>");

            setTimeout(function() {
                x = $(".liberal0");
                x[0].classList.remove("liberal0");
                x[0].classList.add("liberal" + count);
            }, 100);
        } else if (data.custom === 'tracker') {
            $("#tracker")[0].className = '';
            $("#tracker")[0].classList.add("fail" + data.message);
            $("#tracker")[0].classList.add("electiontracker");
            return;
        }
        else if (data.custom && data.custom !== user && data.custom !== 'sit' && data.custom !== 'vote' && data.custom !== 'announcement') {
            return;
        }

        $("#messages").removeClass('hidden');

        let t = isScrolledToBottom;
        let q = $('#messages').append(this.renderMessage(data));
        if (t) {
            out.scrollTop = out.scrollHeight - out.clientHeight;
        }

        return q;
    },
    renderMessage: function (data) {
        if (data.custom) return "<p class='system'>" + data.message + '</p>';
        return "<p class=\"playername\"><strong class=\"" + data.user + "\">" + data.user + "</strong>: " + data.message + "</p>\n" +
            "<script>\n" +
            "    elo = " + data.elo + ";\n" +
            "\n" +
            "    if (elo < 1500) {\n" +
            "        grade = 0;\n" +
            "    } else if (elo > 2000) {\n" +
            "        grade = 500 / 5;\n" +
            "    } else {\n" +
            "        grade = (elo - 1500) / 5;\n" +
            "    }\n" +
            "\n" +
            "    Array.from(document.getElementsByClassName(\"" + data.user + "\")).forEach(x => {x.classList.remove(...x.classList); x.classList.add(\"" + data.user + "\"); x.classList.add(\"elo\" + grade);});\n" +
            "</script>\n"
    }
});