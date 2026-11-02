-- yamato wiki schema + seed.
--
-- Applied idempotently on every app startup (db.go). Because the Cloud SQL
-- instance is private-IP only, there is no convenient out-of-band psql path, so
-- the app is the migrator. The seed uses ON CONFLICT (slug) DO UPDATE, making
-- this file the source of truth: redeploying refreshes article content.

CREATE TABLE IF NOT EXISTS articles (
    slug       text PRIMARY KEY,
    title      text NOT NULL,
    category   text NOT NULL,
    body       text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS articles_category_idx ON articles (category);

-- Full-text search: a generated tsvector column over title+body (title weighted
-- higher), kept in sync by a trigger so /wiki/search can use plainto_tsquery +
-- ts_rank against a GIN index. All ADD/CREATE statements are IF NOT EXISTS or
-- OR REPLACE so this block is safe to re-run on every app startup.
ALTER TABLE articles ADD COLUMN IF NOT EXISTS tsv tsvector;

CREATE INDEX IF NOT EXISTS articles_tsv_idx ON articles USING GIN (tsv);

CREATE OR REPLACE FUNCTION articles_tsv_refresh() RETURNS trigger AS $$
BEGIN
    NEW.tsv :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.body,  '')), 'B');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS articles_tsv_trg ON articles;
CREATE TRIGGER articles_tsv_trg
    BEFORE INSERT OR UPDATE OF title, body ON articles
    FOR EACH ROW EXECUTE FUNCTION articles_tsv_refresh();

INSERT INTO articles (slug, title, category, body) VALUES

('space-battleship-yamato', 'Space Battleship Yamato (the Argo)', 'Ships',
'Space Battleship Yamato is the flagship of Earth''s last hope, and arguably the most consequential vessel ever built by human hands. To outside eyes she appears to be the resurrected hulk of the 20th-century Imperial Japanese Navy battleship Yamato, sunk in the closing months of the Second World War and left to rust on the seabed off Okinawa. To those who built her, the old hull is camouflage and keel — a familiar silhouette under which Earth''s last engineers welded a starship. In the English Star Blazers adaptation she sails under the name Argo, a deliberate echo of the mythic vessel that once carried heroes to a distant shore.

The reconstruction was possible only because the oceans had retreated. Gamilon planet bombs had baked the surface of Earth into rust-colored desert, exposing the rotted hull where it had lain for generations. Beneath that cover, in a vast concealed dock, the Earth Defense Force rebuilt her around the salvaged plans of the Wave-Motion Engine — plans recovered from a wrecked Iscandarian messenger ship on Mars. The result is something the original shipwrights would scarcely recognize: a single-keel deep-space cruiser carrying a complement of just over a hundred crew, a hangar of Cosmo Tiger and Cosmo Zero fighters, pulse laser turrets along the dorsal line, missile launchers, and the analytical robot IQ-9.

Two systems define her. The Wave-Motion Engine fills the after third of the hull and makes faster-than-light travel possible, allowing the warp jumps that turn a 148,000 light-year journey into something a year-long voyage can swallow. The Wave-Motion Gun, mounted in the bow and fed from the same energy core, is the most powerful single weapon ever placed under a captain''s discretion. Crew speak of it with the wary respect normally reserved for living things.

Her mission is simple to state and almost impossible to execute: reach the planet Iscandar, retrieve the Cosmo DNA from Queen Starsha, and return to Earth before the radioactive contamination from Gamilon''s bombardment finishes off the underground cities. One ship. One year. No relief, no resupply, no second attempt.

What Yamato becomes over that voyage is something more than a warship. She is, in the end, a moving city — engine room, infirmary, mess deck, and gun crew bound together by the certainty that nothing waits for them at home if they fail.'),

('wave-motion-engine', 'Wave-Motion Engine', 'Technology',
'The Wave-Motion Engine is the propulsion plant at the heart of the Yamato and the single piece of technology that makes the entire mission possible. Without it, the journey to Iscandar would take longer than human civilization has existed. With it, the trip becomes a year''s endurance test rather than an impossibility.

Its design did not come from Earth. The plans were transmitted by Queen Starsha of Iscandar, smuggled aboard an unmanned messenger ship that crash-landed on Mars during the early years of the Gamilon bombardment. Earth''s engineers, working from blueprints written in a script no human had ever seen and a physics no terrestrial laboratory had ever measured, spent months translating before the first prototype could even be wound. What they built bears little resemblance to any reactor in the human catalogue. It does not so much burn fuel as fold spacetime, drawing energy from what crew engineers call, only half jokingly, the "tachyon ocean" — the substrate beneath ordinary vacuum.

In practical terms the engine performs two duties. It powers the ship''s sublight drives and life support continuously, and on command it executes a space warp, collapsing a stretch of distance into a single subjective instant. A warp is not a trivial operation. The engine must spin up for long minutes, the hull groans audibly as fields take hold, and during the final seconds before transition the Yamato is functionally blind and motionless. Crew refer to these moments as standing on the edge of the well.

The same core feeds the Wave-Motion Gun, and there lies the central dramatic tension of the ship. The engine cannot warp and fire in the same breath. Captain Avatar must choose: run, or shoot. Whichever he picks leaves the other unavailable for the long minutes the core needs to recover. Sandor and the engineering crew spend a significant portion of the voyage tending this machine, coaxing it through breakdowns, foreign sabotage, and stresses its Iscandarian designers almost certainly never imagined a human crew would inflict on it.'),

('wave-motion-gun', 'The Wave-Motion Gun', 'Technology',
'The Wave-Motion Gun is the Yamato''s primary weapon and, by most reckonings, the most destructive single device humanity has ever fielded. It is a bow-mounted cannon whose muzzle takes up nearly the full width of the ship''s forward armor, and whose firing chamber is in fact the Wave-Motion Engine itself. To fire the gun, the engineering crew diverts almost the entire output of the engine forward through a series of focusing rings, releasing it as one tight, terrible beam.

The yield is difficult to describe in conventional terms. A single shot has erased Gamilon fleets, sheared mountain ranges off asteroids, and on at least one occasion punched through a planetary defense barrier that the empire had considered impenetrable. The effect on a planet''s surface, were one ever fired in such a direction, is not something Captain Avatar has been willing to discuss aloud.

That power comes at a price. Charging the gun takes long minutes during which the ship cannot warp, cannot maneuver at full power, and cannot raise its main shielding. The crew must commit to the shot well before they know whether it will land. Once the safeties are released, the countdown is heard throughout the ship — a slow, deliberate cadence that anyone who has served aboard the Yamato comes to know in their bones.

For these reasons the senior officers treat every firing as a moral decision rather than a tactical one. Captain Avatar has been known to refuse the gun even when his bridge officers urged it, and to authorize it only after long silence. Derek Wildstar, who came to the ship spoiling for revenge, learned the discipline of that silence the hard way. By the time the Yamato reaches Iscandar, the Wave-Motion Gun has acquired something close to a personality in the crew''s shared imagination: a sleeping weight in the bow that no one ever quite forgets is awake.'),

('the-mission', 'The Mission to Iscandar', 'Voyage',
'For years before the Yamato''s departure, the Gamilon Empire had been bombarding Earth with planet bombs — kinetic munitions seeded with a slow-burning radioactive isotope that contaminated atmosphere, ocean, and soil alike. The bombardment was methodical rather than dramatic. There was no invasion fleet, no occupation, only the patient and unhurried work of making a world uninhabitable from orbit. By the time humanity understood what was happening, the surface temperature had risen, the oceans had begun to evaporate, and the radiation had driven the survivors into deep underground cities carved beneath what had once been ordinary continents.

Project estimates gave Earth roughly one year of habitability remaining when the messenger ship reached Mars. The vessel was Iscandarian, unmanned, and battered nearly to scrap by its own crossing. Its cargo was twofold: a recorded plea from Queen Starsha of Iscandar offering the gift of a device called the Cosmo DNA, which could cleanse Earth of the radioactive contamination, and the technical schematics of a propulsion system — the Wave-Motion Engine — by which one ship might travel far enough to come and collect it.

Earth chose its vessel and crew under conditions of extraordinary secrecy. The hull would be the resurrected battleship Yamato, rebuilt as a deep-space cruiser in a concealed dock beneath what had once been an inland sea. Captain Avatar, an officer with a decorated record in the unsuccessful early defense actions against Gamilon, was given command despite a medical file the Earth Defense Command would have used to retire any other man. Around him assembled a young crew, many of them survivors of families lost to the bombardment.

The route to Iscandar measures 148,000 light-years, traversing contested Gamilon space, the wreckage of older interstellar wars, and stretches of vacuum no human telescope had ever resolved in detail. The return doubles that distance. The total mission is therefore something on the order of 296,000 light-years and must be completed within the year remaining to Earth — a deadline whose every passing month is marked, on the bridge, by a quiet count that no one ever needs to read aloud.'),

('cosmo-dna', 'The Cosmo DNA', 'Technology',
'The Cosmo DNA is the prize at the end of the voyage and the entire reason the Yamato leaves dock. Despite its name, it is not a biological agent. It is an Iscandarian-built environmental remediation device, compact enough to be carried by hand, whose function is to bind to and neutralize the long-lived radioactive isotopes seeded across Earth by Gamilon planet bombs. In its idle state it resembles a softly lit cylinder mounted on a low pedestal; in operation it transforms the chemistry of an entire biosphere.

How exactly it works is a question Iscandarian science answers in a language Earth has not yet fully translated. Sandor, who studies the device after it is brought aboard, describes its mechanism in cautiously approximate terms: a cascade in which the device itself appears to consume nothing and produce nothing, and yet the surrounding environment is restored. Whether this represents an unimaginable energy density, a manipulation of fundamental constants, or something else entirely is a debate the engineering officers conduct in low voices on the long return leg.

Queen Starsha keeps the device on Iscandar rather than dispatching it. She is explicit about the reason. Earth must come and accept the gift in person, both because the Cosmo DNA cannot survive the kind of unattended journey that wrecked her messenger ship, and because, in her view, a civilization willing to send one vessel that far for the sake of its survival has already proven itself worth saving. The condition is also a kindness: it gives Earth an active role in its own deliverance rather than a passive one.

For the Yamato''s crew, the device is something more than cargo on the return leg. It is the physical proof that the voyage out was not in vain. Wildstar has been seen standing near its containment chamber during the long quiet watches, and the medical staff have reported a measurable lift in morale from the moment it came aboard.'),

('iscandar', 'Iscandar', 'Worlds',
'Iscandar is a small, temperate, lightly populated world that lies 148,000 light-years from Earth and serves as the destination of the Yamato''s voyage. To the crew approaching it for the first time, after months of vacuum and the burned-out battlefields of Gamilon space, the planet looks improbably gentle — a blue-green disc with quiet seas, soft cloud cover, and an axial tilt that gives it long, mild seasons.

Its civilization is, by every measure Earth can take, older and more advanced than humanity''s. Iscandar mastered faster-than-light travel, environmental engineering on a planetary scale, and the energy physics behind the Wave-Motion Engine generations before Earth''s industrial revolution began. And yet, by the time the Yamato arrives, Iscandar is a quiet place. Whole cities stand intact but largely empty. Queen Starsha walks them alone for long stretches. The reasons are not concealed exactly, but they are not told all at once: a long sister-world conflict, a slow decline of population, the loss of family the Queen does not speak about until pressed.

Iscandar shares its corner of space, uncomfortably, with the planet Gamilon. In some tellings the two worlds orbit a common point; in others they are simply close neighbors in stellar terms. Whatever the precise geometry, the proximity is what makes the Yamato''s final approach so dangerous. To reach Starsha, the ship must transit a system in which the empire that bombed Earth maintains its capital, fleet, and personal pride.

For all that, the world itself is unguarded. Iscandar has no warships, no orbital defenses, no soldiers under arms. It defends nothing because, in the long view of its civilization, nothing on Iscandar is worth taking by force from a people who would not give it freely. The Yamato''s arrival is, in this sense, less an invasion than a long-awaited answer to a letter sent into the dark.'),

('queen-starsha', 'Queen Starsha of Iscandar', 'Characters',
'Queen Starsha is the ruler of Iscandar and the benefactor whose recorded message sets the entire story of the Yamato in motion. She is, in practical terms, also the last of her line: by the time the Yamato arrives she rules a planet whose population has dwindled to a remnant, and she carries that loneliness with a composure that the visiting crew find both serene and quietly devastating.

Starsha''s decision to reach out to Earth was not a small one. To send the plans of the Wave-Motion Engine into space was to broadcast a technology her own world had spent generations refining, knowing it might be intercepted by Gamilon, and knowing that putting it into the hands of a wounded human civilization meant trusting that civilization with a weapon as much as a road. She made the choice anyway. In her messages to Captain Avatar she is candid about the calculation: she would rather see the engine misused than see another world die quietly, the way her own has been dying.

Her composure on Iscandar is striking. She receives Captain Avatar and the senior officers in a near-empty palace, walks them through quiet gardens, and answers their questions about the Cosmo DNA without ceremony. She does not boast of her world''s achievements and she does not press Earth for any kind of return. The Cosmo DNA is, in her phrasing, a gift between sisters, not a transaction.

She has at least one personal tie to the story that the crew only gradually unravels: a sister, Sasha, whose fate is bound up with the Gamilon war in ways that touch Mars and the messenger ship directly. Starsha rarely speaks of her unprompted, but the absence is felt in every quiet room of Iscandar.

Her offer stands in deliberate contrast to the methodical aggression of Leader Desslok next door, and the contrast is the moral spine of the entire voyage. Two civilizations, two answers to the question of what one does with great power. Earth''s gratitude is, in the end, the only payment Starsha accepts.'),

('captain-avatar', 'Captain Avatar', 'Characters',
'Captain Avatar — Captain Juzo Okita in the original — is the commanding officer of Space Battleship Yamato, and by general agreement the moral center of the entire voyage. He is a heavy-set, white-bearded man past the age at which most officers have long since retired, and his quiet manner masks a record of command service stretching back through the disastrous early defensive actions against the Gamilon Empire. He is one of the few flag officers from those engagements to have returned with his ship and his honor intact, and he has paid a price for both.

His path to the Yamato is unusual. After the loss of his son in combat — a wound he carries privately but does not hide from those who know him well — Avatar withdrew from active command. He was recalled specifically for this mission, against the recommendation of the Earth Defense Force medical board, on the argument that no other officer alive had both the experience to manage a year-long deep-space command and the temperament to keep a crew of young volunteers from coming apart under the strain. The choice has proven correct, though it has not been kind to him.

On the bridge, Avatar speaks rarely and to the point. He is a listener by temperament, and his most characteristic moments are not orders but the long silences in which he weighs a decision. Bridge crew quickly learn that those silences are not hesitation. When he finally speaks, the course is set. He extends a steady, fatherly patience to Derek Wildstar in particular, whose impulsiveness and grief over the loss of his own brother could easily have wrecked a less generously led ship. The mentorship is not sentimental; Avatar corrects Wildstar firmly and publicly when correction is required. But the warmth is unmistakable.

He carries the voyage forward despite a chronic illness that he has chosen not to disclose to the wider crew. Doctor Sane knows. The senior officers come to suspect. Avatar refuses to allow it to alter his decisions. His private goal, beyond the mission itself, is to see his crew home — to bring back the children of Earth''s last cities and place the Cosmo DNA in their hands. He does not speak of what happens to him afterward.

By the time the Yamato makes its final approach to Iscandar, Avatar has become something more than a commanding officer to the people under him. He has become, quietly and without seeking it, the captain by whom every later officer in Earth''s service will measure themselves.'),

('derek-wildstar', 'Derek Wildstar', 'Characters',
'Derek Wildstar — Susumu Kodai in the original — is the Yamato''s combat group leader, senior fighter pilot, and tactical officer. He boards the ship a young, hot-tempered junior officer with more grief than experience, and over the course of the voyage to Iscandar grows into the man Captain Avatar quietly intends him to become.

The grief is the place to start. His older brother Alex (Mamoru Kodai) commanded the destroyer Yukikaze in the disastrous Battle of Pluto, the engagement in which Captain Avatar''s flagship retreated and the younger Wildstar lost his only family. Derek arrives aboard the Yamato suspecting Avatar of cowardice, and the early weeks of the voyage are charged by that suspicion. The confrontation between them, when it finally comes, is one of the formative scenes of the series. Avatar does not defend himself; he simply explains what happened in his own quiet way and trusts Wildstar to do the work of forgiveness on his own.

Wildstar does. From that point onward, the trajectory of his service is steady. He leads the Cosmo Tiger and Cosmo Zero fighter sorties against Gamilon forces, frequently flying lead himself, and his courage in those engagements is never in serious doubt. What he develops over the voyage is judgment — the ability to stand down when the situation calls for restraint, to take counsel from Mark Venture, Sandor, and Nova, and to recognize, when his own anger is driving a decision, that anger is not the same as command.

His relationships aboard ship round out the picture. He and Mark Venture are inseparable in the way that only officers who have flown together in tight spots can be. He is in love with Nova long before either of them admits it on the record, and the slow, restrained handling of that relationship is one of the warmer through-lines of the long return leg. By the end of the voyage Wildstar has earned a place on the bridge by right, not by appointment, and the crew look to him in the way one looks to a captain in training. Avatar has noticed. So has everyone else.'),

('nova', 'Nova', 'Characters',
'Nova — Yuki Mori in the original — is among the most multivalent officers aboard the Yamato, holding qualifications that on most ships would be parceled out among three or four separate specialists. Over the course of the voyage to Iscandar she serves on radar and sensor operations, in the infirmary as a trained nurse under Doctor Sane, on bridge communications, and at the secondary helm. Her training file is the thickest aboard ship, and she earned every line of it before the Yamato lifted off.

Her background is sparser in the public record than most of her crewmates''. Like many of the volunteers she lost family in the early stages of the Gamilon bombardment, and like Wildstar she came to the Earth Defense Force in part because the underground cities held nothing for her. What she brings to the voyage is a kind of unshowy competence — the steady, attentive presence of someone who has decided, without ceremony, that the people around her are worth taking care of.

Her relationship with Derek Wildstar is the slow heart of the series. It is not a courtship in any formal sense; it is two young officers who keep finding each other in difficult moments and gradually realize that the thing they have been doing all along is loving each other. Captain Avatar is aware. So is Doctor Sane, who is in any case aware of most things. Nova handles the situation with characteristic discretion — she does her job, she keeps Wildstar steady when his temper threatens his judgment, and she does not allow the bridge to become an arena for personal feeling.

Her courage is quiet but not absent. She has gone to the gun deck under fire when crews were down, she has stayed in the infirmary through hull breaches, and she has volunteered for landing parties on worlds where the air was a guess and the natives an unknown. By the end of the voyage she is, in the unofficial reckoning of the crew, indispensable in a way that none of the formal job titles quite capture.'),

('mark-venture', 'Mark Venture', 'Characters',
'Mark Venture — Daisuke Shima in the original — is the Yamato''s chief navigator, the officer responsible for plotting and re-plotting the ship''s course across 148,000 light-years of largely unsurveyed space. If Derek Wildstar is the impulse on the bridge and Captain Avatar the conscience, Mark Venture is the steady hand on the wheel. He is the man at the chart table when the warp comes down and the stars are not where anyone had expected them to be.

His training is in astrogation and stellar cartography, two disciplines that on pre-mission Earth were almost theoretical given how little of the galaxy any human ship had ever visited firsthand. Venture had to invent procedures as he went, building star catalogs from sensor data on long watches and cross-referencing them against the fragmentary Iscandarian charts that came with the Wave-Motion Engine plans. Sandor handles the engine; Venture handles the question of where the engine is taking them.

His temperament is the quiet counterweight to Wildstar''s. The two of them came up together — they have been close since long before either of them set foot on the Yamato — and the friendship is the bedrock of the bridge crew. Venture talks Wildstar down from anger; Wildstar nudges Venture out of the over-cautious places he sometimes retreats into. Their banter is one of the few constants of the voyage and is, by the latter half of the journey, a barometer for the rest of the crew. When Wildstar and Venture are talking easily, things are well.

Venture''s heroism, when it appears, is the kind that does not announce itself. He has held the ship on course through firestorms, replotted entire legs of the journey on the fly when Gamilon ambushes scattered the original plan, and stood watch at the helm through medical emergencies that would have rattled less disciplined officers. He is, in the cliché Captain Avatar would never quite let himself use, the kind of navigator who makes a captain look better than he is. Avatar knows it, and trusts him accordingly.'),

('sandor', 'Sandor', 'Characters',
'Sandor — Shiro Sanada in the original — is the Yamato''s chief science officer and senior engineer, and by most reckonings the smartest single person aboard ship. Where Mark Venture knows where the Yamato is and Captain Avatar knows where she is going, Sandor is the officer who knows, in granular detail, how she actually works. When something aboard breaks, when a new alien technology must be reverse-engineered in an afternoon, or when a Gamilon weapon does something no human textbook describes, the answer almost always runs through him.

His background is unusual. He survived an early Gamilon attack as a young man with severe injuries, and the prosthetic replacements that resulted are part of the reason he is so quietly comfortable with the half-mechanical, half-improvised character of the Yamato''s deeper systems. He understands, from the inside, what it is like to live with a body that has been reconstructed from spare parts and stubbornness. The ship is, in some sense, a larger version of the same problem.

Sandor''s most consequential work is on the Wave-Motion Engine itself. The blueprints that Iscandar transmitted to Earth gave the engineering team the shape of the device but not always its theory. Many of the engine''s emergent behaviors — the way it interacts with strong gravitational fields, the precise edge of its tolerance for emergency restarts — were rediscovered by Sandor on the fly, in real time, with the ship in motion. He is also the officer responsible for nearly every novel piece of equipment improvised on the long voyage, from the gravity-anchor lines used during the asteroid belt encounters to the field repairs of the Cosmo Tigers after combat.

His manner is unflappably calm. He speaks softly, smokes occasionally, and explains intricate technical situations in clear declarative sentences that the bridge officers can act on. He has a quiet but real friendship with IQ-9, in whom he sees a kindred constructed intelligence, and a mutual professional respect with Doctor Sane that mostly takes the form of dry shared looks across a wardroom table. By the end of the voyage Sandor''s name has become a kind of shorthand among the crew: if Sandor says it will hold, it will hold.'),

('iq-9', 'IQ-9 (Analyzer)', 'Characters',
'IQ-9 — Analyzer in the original — is the Yamato''s resident analytical robot and one of the few crew members aboard ship who was not, strictly speaking, born. He is a compact, articulated chassis with a glass-domed sensor head, a pair of mechanical arms that telescope unreasonably far when the occasion demands, and an internal personality matrix that the engineering staff long ago gave up trying to define on paper.

Functionally, IQ-9 is Sandor''s second pair of hands and the bridge''s second pair of eyes. He computes orbital intercepts, runs spectrographic analyses on debris and atmospheres, interrogates damaged Gamilon equipment for usable schematics, and accompanies landing parties as a walking sensor platform with the additional virtue of not needing to breathe. His processing speed is meaningfully ahead of any other system aboard the ship, and his pattern-recognition routines have produced more than one mission-critical insight during contact engagements.

What makes IQ-9 indispensable, however, is not his utility but his personality. He has it, vividly and unmistakably. He is fond of Doctor Sane to a degree the bridge crew find consistently amusing — the running joke that he is sweet on the ship''s physician has its own quiet canon by the middle of the voyage. He bickers with the Cosmo Tiger pilots, deadpans his way through tense bridge moments, and occasionally rolls off in a sulk that would be inappropriate in a piece of equipment of his class if anyone aboard still thought of him as equipment. Nobody does.

There is a real question, never resolved aloud, of whether IQ-9 is conscious in the same sense the rest of the crew is. Captain Avatar treats him as if he is. Sandor, who built much of his current configuration, declines to speculate. The crew long ago settled the matter the practical way: they include him in the count.

He is also the spiritual namesake of the iq9 infrastructure that runs this very wiki — a small honor that, by any reasonable standard, IQ-9 would consider his due.'),

('gamilon-empire', 'The Gamilon Empire', 'Factions',
'The Gamilon Empire is the principal antagonist of the voyage and, by any reasonable definition, one of the most powerful military states in this corner of the galaxy. It is a centralized autocracy ruled absolutely by Leader Desslok, with a fleet doctrine built around saturation bombardment, fighter-screen engagement, and the patient strangulation of inferior worlds. By the time the Yamato leaves Earth, Gamilon has been doing this kind of work for considerably longer than most of the Yamato''s crew has been alive.

Its homeworld is a planet of bluish-skinned humanoids, an atmosphere strange enough to be hostile to human lungs, and an architectural style that favors towering vertical capitals and underground military complexes. Whatever Gamilon was before it became an empire — and there are hints in its capital that it was once a smaller, more contemplative place — has been firmly subordinated to Desslok''s long campaign of expansion. The empire prides itself on its discipline, its technological sophistication, and a self-image of cultural superiority over the worlds it conquers.

Gamilon''s war against Earth is not a war of invasion in the traditional sense. There has been no occupation, no demand for surrender, no negotiated terms. The bombardment with radioactive planet bombs is, in Gamilon strategic doctrine, a slow terraforming operation: render the surface uninhabitable to its current population so that the world can in time be repurposed for Gamilon use. From the empire''s perspective, Earth is not so much an enemy as a piece of real estate undergoing preparation.

The Yamato changes that calculation. By the time the ship has fought its way past the major Gamilon engagement zones — at Pluto, in the asteroid belt, through the Octopus Nebula, and at the floating continent fortress — Earth has gone from a passive resource problem to a personal affair for Leader Desslok. Some of his most senior commanders, Lord Krypt and General Lysis among them, die or are disgraced trying to stop a single battered ship from completing a delivery. It is the kind of small humiliation an empire of Gamilon''s pride does not absorb gracefully.

Whether Gamilon is reformable or merely terrible is one of the slower questions the series asks. By the end of the voyage it has not been fully answered, and the empire remains very much in the field.'),

('leader-desslok', 'Leader Desslok', 'Characters',
'Leader Desslok — Dessler in the original — is the supreme ruler of the Gamilon Empire and Captain Avatar''s opposite number in every dimension that matters. Tall, blue-skinned, fair-haired, and almost preternaturally composed, he presides over his court from a sunken throne in a vast capital chamber, and he addresses subordinates in the calm, slightly amused tone of a man who has not in living memory been told no by anyone whose opinion he was obliged to hear.

His intelligence is not in dispute. The Gamilon strategic apparatus is a personal extension of his mind, and many of the most elegant traps the Yamato survives — the gravity-cell mine field, the artificial sun, the floating continent fortress — were Desslok''s own designs rather than the work of his admirals. He has a gift, in particular, for psychological warfare. He prefers to defeat his opponents through their own assumptions where he can, and he treats brute force as an admission of insufficient creativity.

What makes Desslok genuinely interesting, rather than simply formidable, is the moral weather he carries with him. He is not a sadist. He does not enjoy cruelty for its own sake; he is, in fact, capable of surprising graciousness when the situation does not threaten him. He executes his own underperforming officers without dramatics — the famous trapdoor in the throne room is a personal signature — but he can also extend a kind of cold courtesy to enemies he respects. As the Yamato keeps surviving his traps, his attitude toward the ship and her captain shifts from dismissal through irritation to something disquietingly like admiration. By the late stages of the campaign he has begun to refer to Captain Avatar by name and rank in his private councils, which is more honor than any other Earth officer has ever received from Gamilon.

His relationship with Queen Starsha is the harder, sadder strand of his character. The two rulers know each other; he has, in some accounts, courted her without success; her sister''s fate is bound to his court in ways that he does not discuss in public. Whatever the precise history, it gives his pursuit of the Yamato a private edge that goes beyond strategic interest. The ship is, for him, not only a military problem but a personal affront.

By the time the Yamato makes its final approach, Desslok has become more than an antagonist. He is the mirror against which the moral character of Captain Avatar''s command is measured, and the series treats the contrast with the seriousness it deserves.')

ON CONFLICT (slug) DO UPDATE
SET title = EXCLUDED.title,
    category = EXCLUDED.category,
    body = EXCLUDED.body,
    updated_at = now();
