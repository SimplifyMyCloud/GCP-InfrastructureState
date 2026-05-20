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

INSERT INTO articles (slug, title, category, body) VALUES

('space-battleship-yamato', 'Space Battleship Yamato (the Argo)', 'Ships',
'Space Battleship Yamato is the flagship of Earth''s last hope. Built inside the raised hull of the sunken 20th-century battleship Yamato, the vessel was rebuilt in secret beneath the dried-up seabed of Earth and refitted for deep space. In the English Star Blazers adaptation she is renamed the Argo.

Her defining systems are the Wave-Motion Engine, which makes interstellar travel possible, and the bow-mounted Wave-Motion Gun. She carries a crew of just over a hundred, a complement of fighter craft, and the analytical robot IQ-9.

The ship''s mission: travel to the planet Iscandar and back to save a dying Earth, within a single year.'),

('wave-motion-engine', 'Wave-Motion Engine', 'Technology',
'The Wave-Motion Engine is the faster-than-light propulsion plant at the heart of the Yamato. Its design was not invented on Earth — the plans were transmitted to humanity by Queen Starsha of Iscandar, hidden aboard a wrecked Iscandarian messenger ship that crashed on Mars.

The same energy core feeds the Wave-Motion Gun. Charging the engine for a "space warp" or a main-gun firing leaves the ship briefly vulnerable, a tension that recurs throughout the voyage.'),

('wave-motion-gun', 'The Wave-Motion Gun', 'Technology',
'The Wave-Motion Gun is the Yamato''s primary weapon: a bow-mounted cannon that discharges the focused output of the Wave-Motion Engine in a single devastating beam capable of destroying fleets or splitting continents.

Firing it requires diverting nearly all of the ship''s energy to charge the engine, so the crew must commit to the shot well before it lands. Its power is so great that the senior officers treat every firing as a grave decision rather than a routine tactic.'),

('the-mission', 'The Mission to Iscandar', 'Voyage',
'The Gamilon Empire has bombarded Earth with radioactive planet bombs, driving the survivors into deep underground cities. The surface is poisoned and humanity has roughly one year left before the radiation reaches the last refuges.

Queen Starsha of the planet Iscandar offers a way out: a device called the Cosmo DNA that can cleanse Earth of the radiation. To deliver the plans for the Wave-Motion Engine, she guides a messenger ship to Mars. Earth builds the Yamato around those plans and sends her on a 148,000 light-year journey to Iscandar — a 296,000 light-year round trip that must be completed within the year.'),

('cosmo-dna', 'The Cosmo DNA', 'Technology',
'The Cosmo DNA is the prize at the end of the voyage: an Iscandarian device that can remove the radioactive contamination poisoning Earth. It is the entire reason for the Yamato''s mission — without it, the planet''s remaining population will not survive.

Queen Starsha keeps the device on Iscandar; the Yamato must reach her, receive it, and return home before Earth''s deadline expires.'),

('iscandar', 'Iscandar', 'Worlds',
'Iscandar is a peaceful world 148,000 light-years from Earth, home to Queen Starsha. It is the destination of the Yamato''s voyage and the source of both the Wave-Motion Engine technology and the Cosmo DNA.

Iscandar shares its corner of space with the hostile planet Gamilon — in some tellings the two worlds are near neighbors — which sharpens the danger of the final approach.'),

('queen-starsha', 'Queen Starsha of Iscandar', 'Characters',
'Queen Starsha is the ruler of Iscandar and the benefactor whose message sets the entire story in motion. She transmits the Wave-Motion Engine plans to Earth and promises the Cosmo DNA that can save it.

Her offer is an act of compassion toward a world she has never seen, standing in deliberate contrast to the aggression of the neighboring Gamilon Empire.'),

('captain-avatar', 'Captain Avatar', 'Characters',
'Captain Avatar (Captain Okita in the original) commands the Yamato. A veteran officer carrying the weight of Earth''s survival, he is a steady, fatherly figure to the young crew and the moral center of the ship.

He leads the voyage despite failing health, determined to see the mission through to Iscandar and back.'),

('derek-wildstar', 'Derek Wildstar', 'Characters',
'Derek Wildstar (Susumu Kodai) is the Yamato''s combat group leader and one of its central young officers. Hot-headed and brave, he matures over the voyage from an impulsive fighter into a capable leader under Captain Avatar''s mentorship.'),

('nova', 'Nova', 'Characters',
'Nova (Yuki Mori) serves aboard the Yamato in roles spanning radar, nursing, and bridge operations. Level-headed and compassionate, she is a steadying presence among the crew and is closely tied to Derek Wildstar over the course of the journey.'),

('mark-venture', 'Mark Venture', 'Characters',
'Mark Venture (Daisuke Shima) is the Yamato''s chief navigator, responsible for plotting the ship''s course across 148,000 light-years of unknown space. Calm and dependable, he is Wildstar''s close friend and counterpart on the bridge.'),

('sandor', 'Sandor', 'Characters',
'Sandor (Shiro Sanada) is the Yamato''s science and technology officer — the crew member who understands the ship''s systems most deeply, from the Wave-Motion Engine to its improvised repairs. When something aboard breaks or a new alien technology must be understood, the answer usually runs through Sandor.'),

('iq-9', 'IQ-9 (Analyzer)', 'Characters',
'IQ-9, known as Analyzer in the original, is the Yamato''s analytical robot. He assists the crew with computation, sensor analysis, and engineering tasks, and provides much of the ship''s comic relief — including a famous fondness for Doctor Sane.

As the ship''s resident artificial intelligence, IQ-9 is the spiritual namesake of the iq9 infrastructure that runs this very wiki.'),

('gamilon-empire', 'The Gamilon Empire', 'Factions',
'The Gamilon Empire is the antagonist of the voyage: an aggressive interstellar power that has rendered Earth''s surface uninhabitable with radioactive planet bombs. Throughout the journey the Gamilons repeatedly try to stop the Yamato from reaching Iscandar.'),

('leader-desslok', 'Leader Desslok', 'Characters',
'Leader Desslok (Dessler) is the supreme ruler of the Gamilon Empire and the Yamato''s principal adversary. Cold, brilliant, and proud, he treats the war against Earth as a contest of wills and develops a grudging respect for the Yamato''s crew as they keep surviving his traps.')

ON CONFLICT (slug) DO UPDATE
SET title = EXCLUDED.title,
    category = EXCLUDED.category,
    body = EXCLUDED.body,
    updated_at = now();
