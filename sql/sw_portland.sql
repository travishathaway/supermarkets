SET standard_conforming_strings = OFF;
DROP TABLE IF EXISTS "public"."sw_portland" CASCADE;
DELETE FROM geometry_columns WHERE f_table_name = 'sw_portland' AND f_table_schema = 'public';
BEGIN;
CREATE TABLE "public"."sw_portland" ( "ogc_fid" SERIAL, CONSTRAINT "sw_portland_pk" PRIMARY KEY ("ogc_fid") );
SELECT AddGeometryColumn('public','sw_portland','wkb_geometry',3857,'POLYGON',2);
CREATE INDEX "sw_portland_wkb_geometry_geom_idx" ON "public"."sw_portland" USING GIST ("wkb_geometry");
ALTER TABLE "public"."sw_portland" ADD COLUMN "name" VARCHAR(50);
ALTER TABLE "public"."sw_portland" ADD COLUMN "id" NUMERIC(10,0);
INSERT INTO "public"."sw_portland" ("wkb_geometry" , "name", "id") VALUES ('0103000020110F00000100000039000000AD386E0D17066AC1A49E453DC1C35541AC0736C71A066AC143A553C684BD55412C2052EA18066AC14A08B4FCF7BB5541EC13C4D819066AC1CF21C0C970BA5541C9B79E2A82066AC10C8F588547B85541DC107EA203076AC186B25B4958B855417F9DE3415A076AC19D244F3915B85541D5338911D7076AC1174852FD25B855416F9A9D0B44086AC10338CF9961B8554141857EE5CD086AC1CD2D9714FEB85541E906FDE311096AC15AFFACAFDAB855413E6C6A6D92096AC13B67681A34B9554120055E1EE8096AC1AB02AAAC62B9554152C549E5130A6AC18D6A6517BCB9554152C549E5130A6AC151A823C4F4B8554145DB1727390A6AC1EDF613F0A0B855411EEC49A6AC0A6AC17AF961D179B855414AE85454E70A6AC180BD42EA6AB85541B25D45412C0B6AC1671A17B4B1B8554165678571520B6AC135724FBB46B95541E1BBC07B5F0B6AC100681736E3B955411C046E746D0B6AC14581E27490BA5541D9956FD6750B6AC1271AD625E6BA55416EBE0E5D380B6AC183A5945450BB554150DD6DB3D40A6AC19747D0E08EBC55418E878B38DB0A6AC1E6E85C511EBD5541B8525EA0190B6AC1B8047671A4BD55416D8DD6163C0B6AC1737D635B71BE5541E2ECF8C15B0B6AC1B1A1153B31BF5541114B74FC8E0B6AC17FF94D42C6BF554147CF40DCAB0B6AC1CA0732E060C055418348261BB60B6AC1903919420CC155418348261BB60B6AC1DA16C599AAC155419163901F8D0B6AC112465E1A7DC255419ABA190B730B6AC16A3E7476F2C255412FE3B891350B6AC15F857AFE13C35541879272D9ED0A6AC1C598FA5E60C35541A3C846E29B0A6AC1B08877FB9BC3554111B9BBD3140A6AC1A5CF7D83BDC35541F2A6E2E3B4096AC118CD2FA2E4C35541BAF1DDBD9B096AC1F7D27A8045C45541D4C5413A51096AC1791CCFE93FC4554169EEE0C013096AC1873739EE16C4554182C2443DC9086AC11EC24801D2C355411489733793086AC13D5A8D9678C35541AC13834A4E086AC1CF20BC9042C35541426D5A170D086AC13B2955507CC3554195583346D4076AC19C78F497D7C355412CB20A1393076AC17F11E8482DC45541B88320AE6F076AC16C329D2B65C45541057AE07D49076AC1E060879088C455411164123C24076AC1E060879088C45541A68CB1C2E6066AC16C329D2B65C45541F7151A65B5066AC1002A046C2BC45541877AD8D286066AC10C14362A06C455416868FFE226066AC19B47BC51DBC35541AD386E0D17066AC1A49E453DC1C35541', 'sw_portland', 1);
COMMIT;