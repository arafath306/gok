class _ProfessionalModeScreenState {
    dispose() {
      this[_bioController].dispose();
      super.dispose();
    }
    build(context) {
      let appBarTitle = "প্রফেশনাল মোড";
      if (this[_currentStep] >= 1 && this[_currentStep] <= 4) {
        appBarTitle = "সেটাপ ধাপ " + dart.strSafe(this[_currentStep]) + " / ৪";
      }
      if (this[_currentStep] === 5) {
        appBarTitle = "অভিনন্দন";
      }
      return new scaffold.Scaffold.new({backgroundColor: colors.Colors.white, appBar: new app_bar.AppBar.new({backgroundColor: colors.Colors.white, surfaceTintColor: colors.Colors.transparent, elevation: 0.0, bottom: new preferred_size.PreferredSize.new({preferredSize: C[1] || CT.C1, child: new container.Container.new({color: C[2] || CT.C2, height: 1.0, $creationLocationd_0dea112b090073317d4: C[4] || CT.C4}), $creationLocationd_0dea112b090073317d4: C[5] || CT.C5}), leading: new icon_button.IconButton.new({icon: C[6] || CT.C6, onPressed: dart.fn(() => {
              let $36rec, $36p0, $36result;
              15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this.setState(dart.fn(() => {
                if (this[_currentStep] === 0) {
                  navigator.Navigator.pop(T.ObjectN(), context);
                } else if (this[_currentStep] === 5) {
                  navigator.Navigator.pop(T.ObjectN(), context);
                } else {
                  this[_currentStep] = this[_currentStep] - 1;
                }
              }, T.VoidTovoid())) : ($36rec = this, $36p0 = dart.fn(() => {
                let $36rec, $36result, $36rec$, $36result$;
                if (dart_rti._asInt(dart.dload(this, _currentStep)) === 0) {
                  $36rec = navigator.Navigator;
                  $36result = dart.hotReloadCorrectnessChecks($36rec, 'pop', [T.ObjectN()], [context], null);
                  $36result == dart.validArgumentsSentinel ? $36rec.pop(T.ObjectN(), context) : $36result;
                } else if (dart_rti._asInt(dart.dload(this, _currentStep)) === 5) {
                  $36rec$ = navigator.Navigator;
                  $36result$ = dart.hotReloadCorrectnessChecks($36rec$, 'pop', [T.ObjectN()], [context], null);
                  $36result$ == dart.validArgumentsSentinel ? $36rec$.pop(T.ObjectN(), context) : $36result$;
                } else {
                  dart.dput(this, _currentStep, dart_rti._asInt(dart.dload(this, _currentStep)) - 1);
                }
              }, T.VoidTovoid()), $36result = dart.hotReloadCorrectnessChecks($36rec, 'setState', [], [$36p0], null), $36result == dart.validArgumentsSentinel ? $36rec.setState($36p0) : $36result);
            }, T.VoidTovoid()), $creationLocationd_0dea112b090073317d4: C[10] || CT.C10}), title: new text.Text.new(appBarTitle, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 18.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[11] || CT.C11}), centerTitle: true, $creationLocationd_0dea112b090073317d4: C[12] || CT.C12}), body: new safe_area.SafeArea.new({child: new basic.Column.new({children: (() => {
              let t$360 = _interceptors.JSArray.of(T.JSArrayOfWidget(), []);
              if (this[_currentStep] >= 1 && this[_currentStep] <= 4) t$360.push(new progress_indicator.LinearProgressIndicator.new({value: this[_currentStep] / 4.0, backgroundColor: C[2] || CT.C2, valueColor: C[13] || CT.C13, minHeight: 4.0, $creationLocationd_0dea112b090073317d4: C[15] || CT.C15}));
              t$360.push(new basic.Expanded.new(T.Expanded(), {child: new single_child_scroll_view.SingleChildScrollView.new({physics: C[16] || CT.C16, padding: C[18] || CT.C18, child: this[_buildStepContent](), $creationLocationd_0dea112b090073317d4: C[19] || CT.C19}), $creationLocationd_0dea112b090073317d4: C[20] || CT.C20}));
              t$360.push(this[_buildBottomActionBar]());
              return t$360;
            })(), $creationLocationd_0dea112b090073317d4: C[21] || CT.C21}), $creationLocationd_0dea112b090073317d4: C[22] || CT.C22}), $creationLocationd_0dea112b090073317d4: C[23] || CT.C23});
    }
    [_buildStepContent]() {
      switch (this[_currentStep]) {
        case 0:
          {
            return this[_buildStep0Overview]();
          }
        case 1:
          {
            return this[_buildStep1Category]();
          }
        case 2:
          {
            return this[_buildStep2Bio]();
          }
        case 3:
          {
            return this[_buildStep3Photos]();
          }
        case 4:
          {
            return this[_buildStep4Review]();
          }
        case 5:
          {
            return this[_buildStep5Success]();
          }
        default:
          {
            return C[24] || CT.C24;
          }
      }
    }
    [_buildStep0Overview]() {
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.center, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [C[26] || CT.C26, new basic.Stack.new({alignment: alignment.Alignment.center, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new container.Container.new({width: 100.0, height: 100.0, decoration: C[28] || CT.C28, $creationLocationd_0dea112b090073317d4: C[31] || CT.C31}), C[32] || CT.C32]), $creationLocationd_0dea112b090073317d4: C[35] || CT.C35}), C[36] || CT.C36, new text.Text.new("প্রফেশনাল মোড চালু করুন", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 20.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), textAlign: ui.TextAlign.center, $creationLocationd_0dea112b090073317d4: C[38] || CT.C38}), C[39] || CT.C39, new text.Text.new("আপনার প্রোফাইলে প্রফেশনাল টুল ব্যবহার করে রিচ বাড়ান এবং কন্টেন্ট থেকে আয় করার সুযোগ তৈরি করুন।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 13.0, color: colors.Colors.black54, height: 1.45}), textAlign: ui.TextAlign.center, $creationLocationd_0dea112b090073317d4: C[41] || CT.C41}), C[42] || CT.C42, this[_buildOverviewItem]({icon: icons.Icons.monetization_on_rounded, title: "কন্টেন্ট থেকে আয় করুন", desc: "আপনি যদি যোগ্য হন, তাহলে আপনার কন্টেন্ট থেকে নতুন উপায়ে অর্থ উপার্জন শুরু করতে পারবেন।"}), C[44] || CT.C44, this[_buildOverviewItem]({icon: icons.Icons.bar_chart_rounded, title: "কন্টেন্ট অ্যানালিটিক্স দেখুন", desc: "আপনার দর্শকরা কীভাবে আপনার কন্টেন্টের সাথে সম্পৃক্ত হচ্ছে তার বিস্তারিত পরিসংখ্যান দেখুন।"}), C[46] || CT.C46, this[_buildOverviewItem]({icon: icons.Icons.group_add_rounded, title: "অনুসারী বৃদ্ধি করুন", desc: "আপনার প্রোফাইল ডিফল্টভাবে ফলোয়ার মোডে যাবে যাতে আরও বেশি মানুষের কাছে আপনার কাজ পৌঁছাতে পারে।"})]), $creationLocationd_0dea112b090073317d4: C[48] || CT.C48});
    }
    [_buildOverviewItem](opts) {
      let icon$ = opts && 'icon' in opts ? opts.icon : null;
      let title = opts && 'title' in opts ? opts.title : null;
      let desc = opts && 'desc' in opts ? opts.desc : null;
      return new basic.Row.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new icon.Icon.new(icon$, {color: C[14] || CT.C14, size: 24.0, $creationLocationd_0dea112b090073317d4: C[49] || CT.C49}), C[50] || CT.C50, new basic.Expanded.new(T.Expanded(), {child: new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new(title, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.5, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[52] || CT.C52}), C[53] || CT.C53, new text.Text.new(desc, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.5, color: colors.Colors.black54, height: 1.4}), $creationLocationd_0dea112b090073317d4: C[55] || CT.C55})]), $creationLocationd_0dea112b090073317d4: C[56] || CT.C56}), $creationLocationd_0dea112b090073317d4: C[57] || CT.C57})]), $creationLocationd_0dea112b090073317d4: C[58] || CT.C58});
    }
    [_buildStep1Category]() {
      let categories = _interceptors.JSArray.of(T.JSArrayOfString(), ["Digital Creator", "Blogger", "Writer", "Artist", "Gamer", "Photographer"]);
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: (() => {
          let t$361 = _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new("আপনার ক্যাটাগরি নির্বাচন করুন (Select Category)", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 16.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[59] || CT.C59}), new text.Text.new("আপনার প্রোফাইলে কি ধরণের কন্টেন্ট তৈরি করেন তা সিলেক্ট করুন যা আপনার প্রোফাইলের নামের নিচে দেখা যাবে।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[60] || CT.C60}), C[61] || CT.C61]);
          t$361[$addAll](categories[$map](T.Widget(), dart.fn(cat => {
            let isSelected = (15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this[_selectedCategory] : dart_rti._asString(dart.dload(this, _selectedCategory))) === cat;
            return new container.Container.new({margin: C[63] || CT.C63, decoration: new box_decoration.BoxDecoration.new({color: isSelected ? C[30] || CT.C30 : colors.Colors.white, borderRadius: new border_radius.BorderRadius.circular(12.0), border: box_border.Border.all({color: isSelected ? C[14] || CT.C14 : C[2] || CT.C2, width: isSelected ? 2.0 : 1.0})}), child: new list_tile.ListTile.new({onTap: dart.fn(() => {
                  let $36rec, $36p0, $36result;
                  return 15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this.setState(dart.fn(() => this[_selectedCategory] = cat, T.VoidTovoid())) : ($36rec = this, $36p0 = dart.fn(() => dart.dput(this, _selectedCategory, cat), T.VoidTovoid()), $36result = dart.hotReloadCorrectnessChecks($36rec, 'setState', [], [$36p0], null), $36result == dart.validArgumentsSentinel ? $36rec.setState($36p0) : $36result);
                }, T.VoidTovoid()), title: new text.Text.new(cat, {style: google_fonts_all_parts$46g.GoogleFonts.outfit({fontSize: 14.0, fontWeight: ui.FontWeight.bold, color: isSelected ? C[14] || CT.C14 : colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[64] || CT.C64}), trailing: isSelected ? C[65] || CT.C65 : null, $creationLocationd_0dea112b090073317d4: C[68] || CT.C68}), $creationLocationd_0dea112b090073317d4: C[69] || CT.C69});
          }, T.StringToContainer())));
          return t$361;
        })(), $creationLocationd_0dea112b090073317d4: C[70] || CT.C70});
    }
    [_buildStep2Bio]() {
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new("সংক্ষিপ্ত পরিচিতি যোগ করুন (Add Bio)", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 16.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[71] || CT.C71}), new text.Text.new("অন্যান্য ব্যবহারকারীরা যখন আপনার প্রোফাইল পরিদর্শন করবে তখন তারা এই পরিচিতিটি দেখতে পাবে।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[72] || CT.C72}), C[73] || CT.C73, new text_field.TextField.new({controller: this[_bioController], maxLines: 4, maxLength: 101, decoration: new input_decorator.InputDecoration.new({isDense: true, hintText: "আপনার সম্পর্কে কিছু লিখুন...", hintStyle: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({color: colors.Colors.black38}), filled: true, fillColor: C[75] || CT.C75, border: new input_border.OutlineInputBorder.new({borderRadius: new border_radius.BorderRadius.circular(12.0), borderSide: C[76] || CT.C76}), enabledBorder: new input_border.OutlineInputBorder.new({borderRadius: new border_radius.BorderRadius.circular(12.0), borderSide: C[76] || CT.C76}), focusedBorder: new input_border.OutlineInputBorder.new({borderRadius: new border_radius.BorderRadius.circular(12.0), borderSide: C[78] || CT.C78})}), style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.0}), $creationLocationd_0dea112b090073317d4: C[79] || CT.C79})]), $creationLocationd_0dea112b090073317d4: C[80] || CT.C80});
    }
    [_buildStep3Photos]() {
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new("প্রোফাইল ও কভার ছবি চেক (Photos Verification)", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 16.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[81] || CT.C81}), new text.Text.new("প্রফেশনাল মোড কার্যকর করতে একটি সুন্দর প্রোফাইল এবং কভার ছবি থাকা গুরুত্বপূর্ণ।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[82] || CT.C82}), C[83] || CT.C83, this[_buildVerificationTile]({title: "প্রোফাইল ছবি যুক্ত করা আছে", desc: "একটি সুন্দর প্রোফাইল ছবি আপনার কন্টেন্ট ক্রিয়েটর ইমেজকে রিপ্রেজেন্ট করে।", icon: icons.Icons.person_rounded}), C[85] || CT.C85, this[_buildVerificationTile]({title: "কভার ছবি যুক্ত করা আছে", desc: "কভার ফটো আপনার প্রোফাইল ভিজিটরদের আকর্ষণ করতে সাহায্য করে।", icon: icons.Icons.image_rounded})]), $creationLocationd_0dea112b090073317d4: C[87] || CT.C87});
    }
    [_buildVerificationTile](opts) {
      let title = opts && 'title' in opts ? opts.title : null;
      let desc = opts && 'desc' in opts ? opts.desc : null;
      let icon$ = opts && 'icon' in opts ? opts.icon : null;
      return new container.Container.new({padding: C[88] || CT.C88, decoration: new box_decoration.BoxDecoration.new({color: colors.Colors.white, borderRadius: new border_radius.BorderRadius.circular(12.0), border: box_border.Border.all({color: C[2] || CT.C2})}), child: new basic.Row.new({children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new circle_avatar.CircleAvatar.new({backgroundColor: C[89] || CT.C89, radius: 20.0, child: new icon.Icon.new(icon$, {color: C[90] || CT.C90, size: 20.0, $creationLocationd_0dea112b090073317d4: C[91] || CT.C91}), $creationLocationd_0dea112b090073317d4: C[92] || CT.C92}), C[93] || CT.C93, new basic.Expanded.new(T.Expanded(), {child: new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new(title, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 13.5, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[95] || CT.C95}), new text.Text.new(desc, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 11.5, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[96] || CT.C96})]), $creationLocationd_0dea112b090073317d4: C[97] || CT.C97}), $creationLocationd_0dea112b090073317d4: C[98] || CT.C98}), C[99] || CT.C99]), $creationLocationd_0dea112b090073317d4: C[106] || CT.C106}), $creationLocationd_0dea112b090073317d4: C[107] || CT.C107});
    }
    [_buildStep4Review]() {
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new("প্রাইভেসি ও সেটআপ রিভিউ (Review Details)", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 16.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[108] || CT.C108}), new text.Text.new("সেটআপ সম্পন্ন করার পূর্বে ডিফল্ট পাবলিক পোস্ট অপশনগুলো নিশ্চিত করে নিন।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[109] || CT.C109}), C[110] || CT.C110, new container.Container.new({decoration: new box_decoration.BoxDecoration.new({color: colors.Colors.white, borderRadius: new border_radius.BorderRadius.circular(12.0), border: box_border.Border.all({color: C[2] || CT.C2})}), child: new basic.Column.new({children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new switch_list_tile.SwitchListTile.new({value: this[_defaultPublicPost], onChanged: dart.fn(val => {
                    let $36rec, $36p0, $36result;
                    return 15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this.setState(dart.fn(() => this[_defaultPublicPost] = val, T.VoidTovoid())) : ($36rec = this, $36p0 = dart.fn(() => dart.dput(this, _defaultPublicPost, val), T.VoidTovoid()), $36result = dart.hotReloadCorrectnessChecks($36rec, 'setState', [], [$36p0], null), $36result == dart.validArgumentsSentinel ? $36rec.setState($36p0) : $36result);
                  }, T.boolTovoid()), title: new text.Text.new("ডিফল্ট পোস্ট অডিয়েন্স পাবলিক করুন", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 13.5, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[112] || CT.C112}), subtitle: new text.Text.new("নতুন ফলোয়ারদের আপনার আপলোড করা ছবি/পোস্টগুলো দেখানোর অনুমতি দিন।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 11.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[113] || CT.C113}), activeThumbColor: C[14] || CT.C14, $creationLocationd_0dea112b090073317d4: C[114] || CT.C114}), C[115] || CT.C115, new switch_list_tile.SwitchListTile.new({value: this[_profileInsightsEnable], onChanged: dart.fn(val => {
                    let $36rec, $36p0, $36result;
                    return 15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this.setState(dart.fn(() => this[_profileInsightsEnable] = val, T.VoidTovoid())) : ($36rec = this, $36p0 = dart.fn(() => dart.dput(this, _profileInsightsEnable, val), T.VoidTovoid()), $36result = dart.hotReloadCorrectnessChecks($36rec, 'setState', [], [$36p0], null), $36result == dart.validArgumentsSentinel ? $36rec.setState($36p0) : $36result);
                  }, T.boolTovoid()), title: new text.Text.new("অ্যানালিটিক্স টুল সক্রিয় করুন", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 13.5, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[117] || CT.C117}), subtitle: new text.Text.new("আপনার প্রোফাইলের উইকলি/মান্থলি পারফরম্যান্স ডাটা অ্যাক্সেস করুন।", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 11.0, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[118] || CT.C118}), activeThumbColor: C[14] || CT.C14, $creationLocationd_0dea112b090073317d4: C[119] || CT.C119})]), $creationLocationd_0dea112b090073317d4: C[120] || CT.C120}), $creationLocationd_0dea112b090073317d4: C[121] || CT.C121})]), $creationLocationd_0dea112b090073317d4: C[122] || CT.C122});
    }
    [_buildStep5Success]() {
      return new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.center, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [C[123] || CT.C123, new tween_animation_builder.TweenAnimationBuilder.new(T.TweenAnimationBuilderOfdouble(), {duration: C[125] || CT.C125, tween: new tween.Tween.new(T.TweenOfdouble(), {begin: 0.0, end: 1.0}), curve: curves.Curves.elasticOut, builder: dart.fn((context, value, child) => new basic.Transform.scale({scale: value, child: child, $creationLocationd_0dea112b090073317d4: C[126] || CT.C126}), T.BuildContextAnddoubleAndWidgetNToTransform()), child: new container.Container.new({width: 86.0, height: 86.0, decoration: C[127] || CT.C127, child: C[128] || CT.C128, $creationLocationd_0dea112b090073317d4: C[130] || CT.C130}), $creationLocationd_0dea112b090073317d4: C[131] || CT.C131}), C[132] || CT.C132, new text.Text.new("অভিনন্দন!", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 22.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), textAlign: ui.TextAlign.center, $creationLocationd_0dea112b090073317d4: C[134] || CT.C134}), C[135] || CT.C135, new text.Text.new("আপনার প্রোফাইলে প্রফেশনাল মোড সফলভাবে চালু করা হয়েছে!", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.5, color: colors.Colors.black54, fontWeight: ui.FontWeight.bold}), textAlign: ui.TextAlign.center, $creationLocationd_0dea112b090073317d4: C[137] || CT.C137}), C[138] || CT.C138, new container.Container.new({padding: C[140] || CT.C140, decoration: new box_decoration.BoxDecoration.new({color: colors.Colors.white, borderRadius: new border_radius.BorderRadius.circular(16.0), border: box_border.Border.all({color: C[2] || CT.C2})}), child: new basic.Column.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new text.Text.new("পরবর্তী পদক্ষেপ (Next Steps):", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.0, fontWeight: ui.FontWeight.bold, color: colors.Colors.black87}), $creationLocationd_0dea112b090073317d4: C[141] || CT.C141}), C[142] || CT.C142, this[_buildSuccessStepBullet]("১", "প্রফেশনাল ড্যাশবোর্ড থেকে আপনার রিচ বিশ্লেষণ করুন।"), this[_buildSuccessStepBullet]("২", "নিয়মিত মানসম্মত পোস্ট আপলোড করে এনগেজমেন্ট বাড়ান।"), this[_buildSuccessStepBullet]("৩", "মonetization অপশনগুলো আনলক করতে ফলোয়ার সংখ্যা বাড়ান।")]), $creationLocationd_0dea112b090073317d4: C[147] || CT.C147}), $creationLocationd_0dea112b090073317d4: C[148] || CT.C148})]), $creationLocationd_0dea112b090073317d4: C[149] || CT.C149});
    }
    [_toBengaliNumber](englishNumber) {
      let translation = C[150] || CT.C150;
      return englishNumber[$split]("")[$map](T.String(), dart.fn(char => {
        let $36rec, $36result, t$362;
        t$362 = 15 === dart.global.dartDevEmbedder.hotReloadGeneration ? translation[$_get](char) : ($36rec = translation, $36result = dart.hotReloadCorrectnessChecks($36rec, $_get, [], [char], null), $36result == dart.validArgumentsSentinel ? dart_rti._asStringQ($36rec[$_get](char)) : dart_rti._asStringQ($36result));
        return t$362 == null ? char : t$362;
      }, T.StringToString()))[$join]();
    }
    [_buildSuccessStepBullet](num, text$) {
      return new basic.Padding.new({padding: C[151] || CT.C151, child: new basic.Row.new({crossAxisAlignment: flex.CrossAxisAlignment.start, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [new circle_avatar.CircleAvatar.new({radius: 9.0, backgroundColor: C[30] || CT.C30, child: new text.Text.new(this[_toBengaliNumber](num), {style: google_fonts_all_parts$46g.GoogleFonts.outfit({fontSize: 10.0, fontWeight: ui.FontWeight.bold, color: C[14] || CT.C14}), $creationLocationd_0dea112b090073317d4: C[152] || CT.C152}), $creationLocationd_0dea112b090073317d4: C[153] || CT.C153}), C[154] || CT.C154, new basic.Expanded.new(T.Expanded(), {child: new text.Text.new(text$, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 12.5, color: colors.Colors.black54}), $creationLocationd_0dea112b090073317d4: C[156] || CT.C156}), $creationLocationd_0dea112b090073317d4: C[157] || CT.C157})]), $creationLocationd_0dea112b090073317d4: C[158] || CT.C158}), $creationLocationd_0dea112b090073317d4: C[159] || CT.C159});
    }
    [_buildBottomActionBar]() {
      let showAction = this[_currentStep] <= 4;
      if (!showAction) {
        return new container.Container.new({padding: C[160] || CT.C160, decoration: new box_decoration.BoxDecoration.new({color: colors.Colors.white, boxShadow: _interceptors.JSArray.of(T.JSArrayOfBoxShadow(), [new box_shadow.BoxShadow.new({color: colors.Colors.black.withAlpha(10), blurRadius: 10.0, offset: C[161] || CT.C161})])}), child: new basic.SizedBox.new({width: 1 / 0, height: 48.0, child: new elevated_button.ElevatedButton.new({onPressed: dart.fn(() => {
                let $36rec, $36p0, $36result;
                15 === dart.global.dartDevEmbedder.hotReloadGeneration ? navigator.Navigator.pop(T.ObjectN(), this.context) : ($36rec = navigator.Navigator, $36p0 = T.BuildContext()[_as](dart.dload(this, 'context')), $36result = dart.hotReloadCorrectnessChecks($36rec, 'pop', [T.ObjectN()], [$36p0], null), $36result == dart.validArgumentsSentinel ? $36rec.pop(T.ObjectN(), $36p0) : $36result);
              }, T.VoidTovoid()), style: elevated_button.ElevatedButton.styleFrom({backgroundColor: C[90] || CT.C90, foregroundColor: colors.Colors.white, shape: new rounded_rectangle_border.RoundedRectangleBorder.new({borderRadius: new border_radius.BorderRadius.circular(10.0)}), elevation: 0.0}), child: new text.Text.new("ড্যাশবোর্ডে যান", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 15.0, fontWeight: ui.FontWeight.bold}), $creationLocationd_0dea112b090073317d4: C[162] || CT.C162}), $creationLocationd_0dea112b090073317d4: C[163] || CT.C163}), $creationLocationd_0dea112b090073317d4: C[164] || CT.C164}), $creationLocationd_0dea112b090073317d4: C[165] || CT.C165});
      }
      let actionLabel = "চালু করুন";
      if (this[_currentStep] >= 1 && this[_currentStep] <= 3) actionLabel = "পরবর্তী ধাপ (Next)";
      if (this[_currentStep] === 4) actionLabel = "সম্পূর্ণ করুন (Complete)";
      return new container.Container.new({padding: C[160] || CT.C160, decoration: new box_decoration.BoxDecoration.new({color: colors.Colors.white, boxShadow: _interceptors.JSArray.of(T.JSArrayOfBoxShadow(), [new box_shadow.BoxShadow.new({color: colors.Colors.black.withAlpha(5), blurRadius: 8.0, offset: C[166] || CT.C166})])}), child: new basic.SizedBox.new({width: 1 / 0, height: 48.0, child: new elevated_button.ElevatedButton.new({onPressed: dart.fn(() => {
              let $36rec, $36p0, $36result, $36rec$, $36n0, $36n1, $36n2, $36result$, $36rec$0, $36p0$, $36result$0;
              if ((15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this[_currentStep] : dart_rti._asInt(dart.dload(this, _currentStep))) === 4) {
                let navigator$ = 15 === dart.global.dartDevEmbedder.hotReloadGeneration ? navigator.Navigator.of(this.context) : ($36rec = navigator.Navigator, $36p0 = T.BuildContext()[_as](dart.dload(this, 'context')), $36result = dart.hotReloadCorrectnessChecks($36rec, 'of', [], [$36p0], null), $36result == dart.validArgumentsSentinel ? T.NavigatorState()[_as]($36rec.of($36p0)) : T.NavigatorState()[_as]($36result));
                15 === dart.global.dartDevEmbedder.hotReloadGeneration ? dialog.showDialog(T.dynamic(), {context: this.context, barrierDismissible: false, builder: dart.fn(ctx => {
                    async.Future.delayed(T.FutureOfNull(), C[167] || CT.C167, dart.fn(() => {
                      if (!this.mounted) return;
                      navigator$.pop(T.ObjectN());
                      professional_mode_screen.ProfessionalModeScreen.isActive = true;
                      this.setState(dart.fn(() => {
                        this[_currentStep] = 5;
                      }, T.VoidTovoid()));
                    }, T.VoidToNull()));
                    return new dialog.AlertDialog.new({shape: new rounded_rectangle_border.RoundedRectangleBorder.new({borderRadius: new border_radius.BorderRadius.circular(16.0)}), content: new basic.Column.new({mainAxisSize: flex.MainAxisSize.min, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [C[168] || CT.C168, C[170] || CT.C170, C[173] || CT.C173, new text.Text.new("সেটআপ সম্পূর্ণ করা হচ্ছে...", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.0, fontWeight: ui.FontWeight.bold}), $creationLocationd_0dea112b090073317d4: C[175] || CT.C175}), C[176] || CT.C176, new text.Text.new("অনুগ্রহ করে অপেক্ষা করুন...", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 11.5, color: colors.Colors.black45}), $creationLocationd_0dea112b090073317d4: C[178] || CT.C178})]), $creationLocationd_0dea112b090073317d4: C[179] || CT.C179}), $creationLocationd_0dea112b090073317d4: C[180] || CT.C180});
                  }, T.BuildContextToAlertDialog())}) : ($36rec$ = dialog, $36n0 = T.BuildContext()[_as](dart.dload(this, 'context')), $36n1 = false, $36n2 = dart.fn(ctx => {
                  async.Future.delayed(T.FutureOfNull(), C[167] || CT.C167, dart.fn(() => {
                    let $36rec, $36result, $36rec$, $36p0, $36result$;
                    if (!dart_rti._asBool(dart.dload(this, 'mounted'))) return;
                    $36rec = navigator$;
                    $36result = dart.hotReloadCorrectnessChecks($36rec, 'pop', [T.ObjectN()], [], null);
                    $36result == dart.validArgumentsSentinel ? $36rec.pop(T.ObjectN()) : $36result;
                    professional_mode_screen.ProfessionalModeScreen.isActive = true;
                    $36rec$ = this;
                    $36p0 = dart.fn(() => {
                      dart.dput(this, _currentStep, 5);
                    }, T.VoidTovoid());
                    $36result$ = dart.hotReloadCorrectnessChecks($36rec$, 'setState', [], [$36p0], null);
                    $36result$ == dart.validArgumentsSentinel ? $36rec$.setState($36p0) : $36result$;
                  }, T.VoidToNull()));
                  return new dialog.AlertDialog.new({shape: new rounded_rectangle_border.RoundedRectangleBorder.new({borderRadius: new border_radius.BorderRadius.circular(16.0)}), content: new basic.Column.new({mainAxisSize: flex.MainAxisSize.min, children: _interceptors.JSArray.of(T.JSArrayOfWidget(), [C[168] || CT.C168, C[170] || CT.C170, C[173] || CT.C173, new text.Text.new("সেটআপ সম্পূর্ণ করা হচ্ছে...", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 14.0, fontWeight: ui.FontWeight.bold}), $creationLocationd_0dea112b090073317d4: C[175] || CT.C175}), C[176] || CT.C176, new text.Text.new("অনুগ্রহ করে অপেক্ষা করুন...", {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 11.5, color: colors.Colors.black45}), $creationLocationd_0dea112b090073317d4: C[178] || CT.C178})]), $creationLocationd_0dea112b090073317d4: C[179] || CT.C179}), $creationLocationd_0dea112b090073317d4: C[180] || CT.C180});
                }, T.BuildContextToAlertDialog()), $36result$ = dart.hotReloadCorrectnessChecks($36rec$, 'showDialog', [T.dynamic()], [], {context: $36n0, barrierDismissible: $36n1, builder: $36n2}), $36result$ == dart.validArgumentsSentinel ? T.Future()[_as]($36rec$.showDialog(T.dynamic(), {context: $36n0, barrierDismissible: $36n1, builder: $36n2})) : T.Future()[_as]($36result$));
              } else {
                15 === dart.global.dartDevEmbedder.hotReloadGeneration ? this.setState(dart.fn(() => {
                  this[_currentStep] = this[_currentStep] + 1;
                }, T.VoidTovoid())) : ($36rec$0 = this, $36p0$ = dart.fn(() => {
                  dart.dput(this, _currentStep, dart_rti._asInt(dart.dload(this, _currentStep)) + 1);
                }, T.VoidTovoid()), $36result$0 = dart.hotReloadCorrectnessChecks($36rec$0, 'setState', [], [$36p0$], null), $36result$0 == dart.validArgumentsSentinel ? $36rec$0.setState($36p0$) : $36result$0);
              }
            }, T.VoidTovoid()), style: elevated_button.ElevatedButton.styleFrom({backgroundColor: C[14] || CT.C14, foregroundColor: colors.Colors.white, shape: new rounded_rectangle_border.RoundedRectangleBorder.new({borderRadius: new border_radius.BorderRadius.circular(10.0)}), elevation: 0.0}), child: new text.Text.new(actionLabel, {style: google_fonts_all_parts$46g.GoogleFonts.hindSiliguri({fontSize: 15.0, fontWeight: ui.FontWeight.bold}), $creationLocationd_0dea112b090073317d4: C[181] || CT.C181}), $creationLocationd_0dea112b090073317d4: C[182] || CT.C182}), $creationLocationd_0dea112b090073317d4: C[183] || CT.C183}), $creationLocationd_0dea112b090073317d4: C[184] || CT.C184});
    }
    static ['_#new#tearOff']() {
      return new professional_mode_screen._ProfessionalModeScreenState.new(T._ProfessionalModeScreenState());
    }
  };
  dart.declareClass(professional_mode_screen, '_ProfessionalModeScreenState', __ProfessionalModeScreenState);
  (professional_mode_screen._ProfessionalModeScreenState.new = function(_ti) {
    this.$ti = this.$ti || _ti || dart.getReifiedType(this);
    this[_currentStep] = 0;
    this[_selectedCategory] = "Digital Creator";
    this[_bioController] = new editable_text.TextEditingController.new(T.TextEditingController(), {text: "ডিজিটাল কন্টেন্ট মেকার ও সোশ্যাল মিডিয়া এনথুসিয়াস্ট।"});
    this[_defaultPublicPost] = true;
    this[_profileInsightsEnable] = true;
    dart.global.Object.getPrototypeOf(professional_mode_screen._ProfessionalModeScreenState).new.call(this, null);
    ;
  }).prototype = professional_mode_screen._ProfessionalModeScreenState.prototype;
  dart.lazyFn(professional_mode_screen._ProfessionalModeScreenState['_#new#tearOff'], () => T.VoidTo_ProfessionalModeScreenState());
  dart.addRtiResources(professional_mode_screen._ProfessionalModeScreenState, ["dak__screens__boost__professional_mode_screen|_ProfessionalModeScreenState"]);
  dart.setMethodSignature(professional_mode_screen._ProfessionalModeScreenState, () => dart.global.Object.setPrototypeOf({
    build: _ti => T.BuildContextToWidget(),
    [_buildStepContent]: _ti => T.VoidToWidget(),
    [_buildStep0Overview]: _ti => T.VoidToWidget(),
    [_buildOverviewItem]: _ti => T.__ToWidget(),
    [_buildStep1Category]: _ti => T.VoidToWidget(),
    [_buildStep2Bio]: _ti => T.VoidToWidget(),
    [_buildStep3Photos]: _ti => T.VoidToWidget(),
    [_buildVerificationTile]: _ti => T.__ToWidget(),
    [_buildStep4Review]: _ti => T.VoidToWidget(),
    [_buildStep5Success]: _ti => T.VoidToWidget(),
    [_toBengaliNumber]: _ti => T.StringToString(),
    [_buildSuccessStepBullet]: _ti => T.StringAndStringToWidget(),
    [_buildBottomActionBar]: _ti => T.VoidToWidget()
  }, dart.getMethods(dart.global.Object.getPrototypeOf(professional_mode_screen._ProfessionalModeScreenState))));
  dart.setMethodsImmediateTargetSignature(professional_mode_screen._ProfessionalModeScreenState, () => dart.global.Object.setPrototypeOf({
    dispose: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    build: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStepContent]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep0Overview]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildOverviewItem]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep1Category]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep2Bio]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep3Photos]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildVerificationTile]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep4Review]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildStep5Success]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_toBengaliNumber]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildSuccessStepBullet]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState",
    [_buildBottomActionBar]: "package:dak/screens/boost/professional_mode_screen.dart:_ProfessionalModeScreenState"
  }, dart.getMethodsImmediateTargets(dart.global.Object.getPrototypeOf(professional_mode_screen._ProfessionalModeScreenState))));
  dart.setLibraryUri(professional_mode_screen._ProfessionalModeScreenState, I[0]);
  dart.setFieldSignature(professional_mode_screen._ProfessionalModeScreenState, () => dart.global.Object.setPrototypeOf({
    [_currentStep]: {
      type: _ti => T.int(),
      isConst: false,
      isFinal: false,
      libraryUri: I[1]
    },
    [_selectedCategory]: {
      type: _ti => T.String(),
      isConst: false,
      isFinal: false,
      libraryUri: I[1]
    },
    [_bioController]: {
      type: _ti => T.TextEditingController(),
      isConst: false,
      isFinal: true,
      libraryUri: I[2]
    },
    [_defaultPublicPost]: {
      type: _ti => T.bool(),
      isConst: false,
      isFinal: false,
      libraryUri: I[1]
    },
    [_profileInsightsEnable]: {
      type: _ti => T.bool(),
      isConst: false,
      isFinal: false,
      libraryUri: I[1]
    }
  }, dart.getFields(dart.global.Object.getPrototypeOf(professional_mode_screen._ProfessionalModeScreenState))));
  (function() {
  }).prototype = professional_mode_screen;
  dart.moduleConstCaches.set("packages/dak/screens/boost/professional_mode_screen.dart", C);
  professional_mode_screen[dartDevEmbedder.linkSymbol] = function link__professional_mode_screen() {
    dart.classExtends(professional_mode_screen.ProfessionalModeScreen, dartDevEmbedder.importLibrary("package:flutter/src/widgets/framework.dart").StatefulWidget);
    dart.classExtends(__ProfessionalModeScreenState, dartDevEmbedder.importLibrary("package:flutter/src/widgets/framework.dart").State);
    dart.classExtends(professional_mode_screen._ProfessionalModeScreenState, dartDevEmbedder.importLibrary("package:flutter/src/widgets/framework.dart").State);
    dart_rti._Universe.addRules(dart.typeUniverse, JSON.parse('{"dak__screens__boost__professional_mode_screen|_ProfessionalModeScreenState":{"State.T":"dak__screens__boost__professional_mode_screen|ProfessionalModeScreen","flutter__src__widgets__framework|State":["dak__screens__boost__professional_mode_screen|ProfessionalModeScreen"],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|State":{"State.T":"1","flutter__src__foundation__diagnostics|Diagnosticable":[]},"dak__screens__boost__professional_mode_screen|ProfessionalModeScreen":{"flutter__src__widgets__framework|StatefulWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|StatefulWidget":{"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|Widget":{"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__foundation__diagnostics|DiagnosticableTree":{"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__editable_text|TextEditingController":{"ValueNotifier.T":"flutter__src__services__text_input|TextEditingValue","flutter__src__foundation__change_notifier|ValueNotifier":["flutter__src__services__text_input|TextEditingValue"],"flutter__src__foundation__change_notifier|ChangeNotifier":[],"ValueListenable.T":"flutter__src__services__text_input|TextEditingValue","flutter__src__foundation__change_notifier|ValueListenable":["flutter__src__services__text_input|TextEditingValue"],"flutter__src__foundation__change_notifier|Listenable":[]},"flutter__src__foundation__change_notifier|ValueNotifier":{"ValueNotifier.T":"1","flutter__src__foundation__change_notifier|ChangeNotifier":[],"ValueListenable.T":"1","flutter__src__foundation__change_notifier|ValueListenable":["1"],"flutter__src__foundation__change_notifier|Listenable":[]},"flutter__src__foundation__change_notifier|ChangeNotifier":{"flutter__src__foundation__change_notifier|Listenable":[]},"flutter__src__foundation__change_notifier|ValueListenable":{"ValueListenable.T":"1","flutter__src__foundation__change_notifier|Listenable":[]},"_interceptors|JSArray":{"JSArray.E":"1","_interceptors|JavaScriptObject":[],"List.E":"1","core|List":["1"],"JSIndexable.E":"1","_interceptors|JSIndexable":["1"],"_js_helper|TrustedGetRuntimeType":[],"_interceptors|Interceptor":[],"_interceptors|JSObject":[],"Iterable.E":"1","core|Iterable":["1"],"_ListIterable.E":"1","core|_ListIterable":["1"],"EfficientLengthIterable.T":"1","_internal|EfficientLengthIterable":["1"],"HideEfficientLengthIterable.T":"1","_internal|HideEfficientLengthIterable":["1"]},"_interceptors|JavaScriptObject":{"_interceptors|Interceptor":[],"_interceptors|JSObject":[]},"core|List":{"List.E":"1","Iterable.E":"1","core|Iterable":["1"],"_ListIterable.E":"1","core|_ListIterable":["1"],"EfficientLengthIterable.T":"1","_internal|EfficientLengthIterable":["1"],"HideEfficientLengthIterable.T":"1","_internal|HideEfficientLengthIterable":["1"]},"_interceptors|JSIndexable":{"JSIndexable.E":"1"},"core|Iterable":{"Iterable.E":"1"},"core|_ListIterable":{"_ListIterable.E":"1","EfficientLengthIterable.T":"1","_internal|EfficientLengthIterable":["1"],"HideEfficientLengthIterable.T":"1","_internal|HideEfficientLengthIterable":["1"],"Iterable.E":"1","core|Iterable":["1"]},"_internal|EfficientLengthIterable":{"EfficientLengthIterable.T":"1","Iterable.E":"1","core|Iterable":["1"]},"_internal|HideEfficientLengthIterable":{"HideEfficientLengthIterable.T":"1","Iterable.E":"1","core|Iterable":["1"]},"flutter__src__animation__animations|AlwaysStoppedAnimation":{"AlwaysStoppedAnimation.T":"1","Animation.T":"1","flutter__src__animation__animation|Animation":["1"],"flutter__src__foundation__change_notifier|Listenable":[],"ValueListenable.T":"1","flutter__src__foundation__change_notifier|ValueListenable":["1"]},"flutter__src__animation__animation|Animation":{"Animation.T":"1","flutter__src__foundation__change_notifier|Listenable":[],"ValueListenable.T":"1","flutter__src__foundation__change_notifier|ValueListenable":["1"]},"flutter__src__widgets__basic|Expanded":{"flutter__src__widgets__basic|Flexible":[],"ParentDataWidget.T":"flutter__src__rendering__flex|FlexParentData","flutter__src__widgets__framework|ParentDataWidget":["flutter__src__rendering__flex|FlexParentData"],"flutter__src__widgets__framework|ProxyWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__basic|Flexible":{"ParentDataWidget.T":"flutter__src__rendering__flex|FlexParentData","flutter__src__widgets__framework|ParentDataWidget":["flutter__src__rendering__flex|FlexParentData"],"flutter__src__widgets__framework|ProxyWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|ParentDataWidget":{"ParentDataWidget.T":"1","flutter__src__widgets__framework|ProxyWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__rendering__flex|FlexParentData":{"ContainerBoxParentData.ChildType":"flutter__src__rendering__box|RenderBox","flutter__src__rendering__box|ContainerBoxParentData":["flutter__src__rendering__box|RenderBox"],"flutter__src__rendering__box|BoxParentData":[],"ContainerParentDataMixin.ChildType":"flutter__src__rendering__box|RenderBox","flutter__src__rendering__object|ContainerParentDataMixin":["flutter__src__rendering__box|RenderBox"],"flutter__src__rendering__object|ParentData":[]},"flutter__src__widgets__framework|ProxyWidget":{"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__rendering__box|ContainerBoxParentData":{"ContainerBoxParentData.ChildType":"1","flutter__src__rendering__box|BoxParentData":[],"ContainerParentDataMixin.ChildType":"1","flutter__src__rendering__object|ContainerParentDataMixin":["1"],"flutter__src__rendering__object|ParentData":[]},"flutter__src__rendering__box|RenderBox":{"flutter__src__rendering__object|RenderObject":[],"flutter__src__gestures__hit_test|HitTestTarget":[],"flutter__src__foundation__diagnostics|DiagnosticableTreeMixin":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__rendering__object|RenderObject":{"flutter__src__gestures__hit_test|HitTestTarget":[],"flutter__src__foundation__diagnostics|DiagnosticableTreeMixin":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__rendering__box|BoxParentData":{"flutter__src__rendering__object|ParentData":[]},"flutter__src__rendering__object|ContainerParentDataMixin":{"ContainerParentDataMixin.ChildType":"1","flutter__src__rendering__object|ParentData":[]},"flutter__src__foundation__diagnostics|DiagnosticableTreeMixin":{"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"core|String":{"Comparable.T":"core|String","core|Comparable":["core|String"],"core|Pattern":[]},"core|Comparable":{"Comparable.T":"1"},"flutter__src__widgets__container|Container":{"flutter__src__widgets__framework|StatelessWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|StatelessWidget":{"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__tween_animation_builder|TweenAnimationBuilder":{"TweenAnimationBuilder.T":"1","flutter__src__widgets__implicit_animations|ImplicitlyAnimatedWidget":[],"flutter__src__widgets__framework|StatefulWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__implicit_animations|ImplicitlyAnimatedWidget":{"flutter__src__widgets__framework|StatefulWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"core|double":{"core|num":[],"Comparable.T":"core|num","core|Comparable":["core|num"]},"core|num":{"Comparable.T":"core|num","core|Comparable":["core|num"]},"flutter__src__animation__tween|Tween":{"Tween.T":"1","Animatable.T":"1","flutter__src__animation__tween|Animatable":["1"]},"flutter__src__animation__tween|Animatable":{"Animatable.T":"1"},"flutter__src__widgets__basic|Transform":{"flutter__src__widgets__framework|SingleChildRenderObjectWidget":[],"flutter__src__widgets__framework|RenderObjectWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|SingleChildRenderObjectWidget":{"flutter__src__widgets__framework|RenderObjectWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__framework|RenderObjectWidget":{"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__painting__box_shadow|BoxShadow":{"ui|Shadow":[]},"flutter__src__widgets__navigator|NavigatorState":{"RestorationMixin.S":"flutter__src__widgets__navigator|Navigator","flutter__src__widgets__restoration|RestorationMixin":["flutter__src__widgets__navigator|Navigator"],"State.T":"flutter__src__widgets__navigator|Navigator","flutter__src__widgets__framework|State":["flutter__src__widgets__navigator|Navigator"],"TickerProviderStateMixin.T":"flutter__src__widgets__navigator|Navigator","flutter__src__widgets__ticker_provider|TickerProviderStateMixin":["flutter__src__widgets__navigator|Navigator"],"flutter__src__scheduler__ticker|TickerProvider":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__restoration|RestorationMixin":{"RestorationMixin.S":"1","State.T":"1","flutter__src__widgets__framework|State":["1"],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__navigator|Navigator":{"flutter__src__widgets__framework|StatefulWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"flutter__src__widgets__ticker_provider|TickerProviderStateMixin":{"TickerProviderStateMixin.T":"1","State.T":"1","flutter__src__widgets__framework|State":["1"],"flutter__src__scheduler__ticker|TickerProvider":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"async|Future":{"Future.T":"1"},"flutter__src__material__dialog|AlertDialog":{"flutter__src__widgets__framework|StatelessWidget":[],"flutter__src__widgets__framework|Widget":[],"flutter__src__foundation__diagnostics|DiagnosticableTree":[],"flutter__src__widgets__widget_inspector|_HasCreationLocation":[],"flutter__src__foundation__diagnostics|Diagnosticable":[]},"core|int":{"core|num":[],"Comparable.T":"core|num","core|Comparable":["core|num"]}}'));
    dart_rti._Universe.deleteRules(dart.typeUniverse, JSON.parse('["flutter__src__foundation__diagnostics|Diagnosticable","flutter__src__widgets__widget_inspector|_HasCreationLocation","flutter__src__foundation__key|Key","core|bool","flutter__src__services__text_input|TextEditingValue","flutter__src__foundation__change_notifier|Listenable","_js_helper|TrustedGetRuntimeType","_interceptors|Interceptor","_interceptors|JSObject","ui|Color","flutter__src__gestures__hit_test|HitTestTarget","flutter__src__rendering__object|ParentData","core|Pattern","flutter__src__widgets__framework|BuildContext","ui|Shadow","flutter__src__scheduler__ticker|TickerProvider","flutter__src__widgets__icon_data|IconData"]'));
    dart.extendEnum(dart.const(Object.setPrototypeOf({
      [_Enum__name]: "sRGB"
    }, ui.ColorSpace.prototype)), {
      get [_Enum_index]() {
        return ui.ColorSpace.values.indexOf(this);
      }
    });
    dart.extendEnum(dart.const(Object.setPrototypeOf({
      [_Enum__name]: "normal"
    }, scroll_physics.ScrollDecelerationRate.prototype)), {
      get [_Enum_index]() {
        return scroll_physics.ScrollDecelerationRate.values.indexOf(this);
      }
    });
    dart.extendEnum(dart.const(Object.setPrototypeOf({
      [_Enum__name]: "circle"
    }, box_border.BoxShape.prototype)), {
      get [_Enum_index]() {
        return box_border.BoxShape.values.indexOf(this);
      }
    });
    dart.extendEnum(dart.const(Object.setPrototypeOf({
      [_Enum__name]: "solid"
    }, borders.BorderStyle.prototype)), {
      get [_Enum_index]() {
        return borders.BorderStyle.values.indexOf(this);
      }
    });
    dart.extendEnum(dart.const(Object.setPrototypeOf({
      [_Enum__name]: "material"
    }, progress_indicator._ActivityIndicatorType.prototype)), {
      get [_Enum_index]() {
        return progress_indicator._ActivityIndicatorType.values.indexOf(this);
      }
    });
  };
  professional_mode_screen[dart.libraryImportUri] = "package:dak/screens/boost/professional_mode_screen.dart";
  return professional_mode_screen;
}), {dartSize: 26745, sourceMapSize: 6849});
dartDevEmbedder.debugger.setSourceMap("packages/dak/screens/boost/professional_mode_screen.dart", '{"version":3,"sourceRoot":"","sources":["professional_mode_screen.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;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","file":"../../../../../../../packages/dak/screens/boost/professional_mode_screen.dart.lib.js"}');

//# sourceMappingURL=professional_mode_screen.dart.lib.js.map
